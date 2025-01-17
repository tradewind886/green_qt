#include "addresslistmodel.h"

#include "account.h"
#include "address.h"
#include "context.h"
#include "task.h"
#include "wallet.h"

AddressListModel::AddressListModel(QObject* parent)
    : QAbstractListModel(parent)
    , m_reload_timer(new QTimer(this))
{
    m_reload_timer->setSingleShot(true);
    m_reload_timer->setInterval(200);
    connect(m_reload_timer, &QTimer::timeout, this, [&] {
        fetch(true);
    });
}

void AddressListModel::setAccount(Account* account)
{
    if (m_account) {
        disconnect(m_account, &Account::addressGenerated, this, &AddressListModel::reload);
        beginResetModel();
        m_addresses.clear();
        m_account = nullptr;
        emit accountChanged();
        endResetModel();
    }
    m_account = account;
    emit accountChanged();
    if (m_account) {
        connect(m_account, &Account::addressGenerated, this, &AddressListModel::reload);
        fetchMore(QModelIndex());
    }
}

void AddressListModel::fetch(bool reset)
{
    if (!m_account) return;

    const auto context = m_account->context();
    if (!context) return;
    const auto wallet = context->wallet();
    if (!wallet) return;

    // TODO: autologout unsets context on the wallet
    // TODO: and this controller should detect that
    // TODO: for now, check wallet's context before continuing
    if (!wallet->context()) return;

    auto get_addresses = new GetAddressesTask(m_last_pointer, m_account);

    connect(get_addresses, &Task::finished, this, [=] {
        m_last_pointer = get_addresses->lastPointer();
        emit fetchingChanged();
        // instantiate missing addresses
        QVector<Address*> addresses;
        for (QJsonValue data : get_addresses->addresses()) {
            auto address = m_account->getOrCreateAddress(data.toObject());
            addresses.append(address);
        }
        if (reset) {
            // just swap rows instead of incremental update
            // this happens after a bump fee for instance
            beginResetModel();
            m_addresses = addresses;
            endResetModel();
        } else if (addresses.size() > 0) {
            // new page of addresses, just append
            beginInsertRows(QModelIndex(), m_addresses.size(), m_addresses.size() + addresses.size() - 1);
            m_addresses.append(addresses);
            endInsertRows();
        }
    });

    context->dispatcher()->add(get_addresses);
}

QHash<int, QByteArray> AddressListModel::roleNames() const
{
    return {
        { AddressRole, "address" },
        { PointerRole, "last_pointer" },
        { AddressStringRole, "address_string" },
        { CountRole, "tx_count" }
    };
}

bool AddressListModel::canFetchMore(const QModelIndex& parent) const
{
    Q_ASSERT(!parent.parent().isValid());
    return m_last_pointer != 1;
}

void AddressListModel::fetchMore(const QModelIndex& parent)
{
    Q_ASSERT(!parent.parent().isValid());
    if (!m_account) return;
    fetch(false);
}

int AddressListModel::rowCount(const QModelIndex& parent) const
{
    Q_UNUSED(parent);
    return m_addresses.size();
}

int AddressListModel::columnCount(const QModelIndex& parent) const
{
    Q_UNUSED(parent);
    return 1;
}

QVariant AddressListModel::data(const QModelIndex& index, int role) const
{
    switch (role)
    {
        case AddressRole:
            return QVariant::fromValue(m_addresses.at(index.row()));
        case PointerRole:
            return QVariant::fromValue(m_addresses.at(index.row())->data()["last_pointer"].toVariant());
        case AddressStringRole:
            return QVariant::fromValue(m_addresses.at(index.row())->data()["address"].toVariant());
        case CountRole:
            return QVariant::fromValue(m_addresses.at(index.row())->data()["tx_count"].toVariant());
    }

    return QVariant();
}

void AddressListModel::reload()
{
    if (!m_account) return;

    m_has_unconfirmed = false;
    m_last_pointer = 0;

    m_reload_timer->start();
}
