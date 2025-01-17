#include "wallet.h"

#include <gdk.h>

#include <QDateTime>
#include <QDebug>
#include <QJsonObject>
#include <QLocale>
#include <QSettings>
#include <QTimer>
#include <QUuid>

#include <type_traits>

#include "activitymanager.h"
#include "context.h"
#include "ga.h"
#include "device.h"
#include "json.h"
#include "network.h"
#include "session.h"
#include "util.h"
#include "walletmanager.h"

#include <nlohmann/json.hpp>

Wallet::Wallet(QObject* parent)
    : QObject(parent)
{
}

Wallet::~Wallet()
{
}

void Wallet::disconnect()
{
    if (m_context) {
        if (m_context->device()) {
            auto activity = m_context->device()->logout();
            ActivityManager::instance()->exec(activity);
        }
        m_context->deleteLater();
        setContext(nullptr);
    }
}

void Wallet::setContext(Context* context)
{
    if (m_context == context) return;
    m_context = context;
    emit contextChanged();
    if (m_context) {
        m_context->setParent(this);
    }
}

QString Wallet::id() const
{
    Q_ASSERT(!m_id.isEmpty());
    return m_id;
}

void Wallet::setName(const QString& name)
{
    if (m_name == name) return;
    m_name = name;
    emit nameChanged();
}

QJsonObject Wallet::pinData() const
{
    if (m_pin_data.isNull()) return {};
    return QJsonDocument::fromJson(m_pin_data).object();
}

void Wallet::reload(bool refresh_accounts)
{
    /*
    auto handler = new GetSubAccountsHandler(session(), refresh_accounts);
    QObject::connect(handler, &Handler::done, this, [this, handler] {
        handler->deleteLater();

        m_accounts.clear();
        for (auto value : handler->subAccounts()) {
            QJsonObject data = value.toObject();
            Account* account = getOrCreateAccount(data);
            account->reload();
            m_accounts.append(account);
        }

        emit accountsChanged();

        if (!m_watch_only) {
            char* data;
            GA_get_watch_only_username(session()->m_session, &data);
            auto username = QString::fromUtf8(data);
            GA_destroy_string(data);
            if (m_username != username) {
                m_username = username;
                emit usernameChanged(m_username);
            }
        }
    });
    QObject::connect(handler, &Handler::resolver, this, [](Resolver* resolver) {
        resolver->resolve();
    });
    handler->exec();
    */
}

bool Wallet::rename(QString name, bool active_focus)
{
    if (!active_focus) name = name.trimmed();
    if (name.isEmpty() && !active_focus) {
        name = WalletManager::instance()->newWalletName();
    }
    if (m_name == name) return false;
    if (active_focus) return false;
    setName(name);
    if (m_name.isEmpty()) return false;
    save();
    return true;
}

void Wallet::save()
{
    Q_ASSERT(QThread::currentThread() == thread());
    Q_ASSERT(!m_id.isEmpty());
    if (!m_is_persisted) return;
    QJsonObject data({
        { "version", 1 },
        { "name", m_name }
    });
    if (m_watch_only) {
        data.insert("username", m_username);
    }
    if (m_network && (m_login_attempts_remaining > 0 || !m_pin_data.isEmpty())) {
        data.insert("network", m_network->id());
        data.insert("login_attempts_remaining", m_login_attempts_remaining);
        data.insert("pin_data", QString::fromLocal8Bit(m_pin_data.toBase64()));
    }
    if (!m_hash_id.isEmpty()) {
        data.insert("hash_id", m_hash_id);
    }
    if (!m_xpub_hash_id.isEmpty()) {
        data.insert("xpub_hash_id", m_xpub_hash_id);
    }
    if (!m_device_details.isEmpty()) {
        data.insert("device_details", m_device_details);
    }
    QFile file(GetDataFile("wallets", m_id));
    bool result = file.open(QFile::WriteOnly | QFile::Truncate);
    Q_ASSERT(result);
    file.write(QJsonDocument(data).toJson());
    result = file.flush();
    Q_ASSERT(result);
}

void Wallet::clearPinData()
{
    setPinData(nullptr, {});
}

void Wallet::setPinData(Network* network, const QByteArray& pin_data)
{
    if (m_network == network && m_pin_data == pin_data) return;
    m_network = network;
    m_pin_data = pin_data;
    emit hasPinDataChanged();
    resetLoginAttempts();
    save();
}

QJsonObject Wallet::convert(const QJsonObject& value) const
{
    if (!m_context) return {};
    auto session = m_context->primarySession();
    if (!session) return {};
    auto details = Json::fromObject(value);
    GA_json* balance;
    int err = GA_convert_amount(session->m_session, details.get(), &balance);
    if (err != GA_OK) return {};
    QJsonObject result = Json::toObject(balance);
    GA_destroy_json(balance);
    return result;
}

QString Wallet::formatAmount(qint64 amount, bool include_ticker) const
{
    const auto session = m_context->primarySession();
    return formatAmount(amount, include_ticker, session->unit());
}

QString Wallet::formatAmount(qint64 amount, bool include_ticker, const QString& unit) const
{
    if (!m_context) return {};
    const auto session = m_context->primarySession();
    const auto effective_unit = unit.isEmpty() ? session->unit() : unit;
    if (effective_unit.isEmpty()) return {};
    auto str = convert({{ "satoshi", amount }}).value(effective_unit == "\u00B5BTC" ? "ubtc" : effective_unit.toLower()).toString();
    auto val = str.toDouble();
    if (val == ((int64_t) val)) {
        str = QLocale::system().toString(val, 'f', 0);
    } else {
        str = QLocale::system().toString(val, 'f', 8);
        str.remove(QRegularExpression("\\.?0+$"));
    }
    if (include_ticker) {
        str += " " + ComputeDisplayUnit(session->network(), effective_unit);
    }
    return str;
}

void Wallet::updateDeviceDetails(const QJsonObject& device_details)
{
    if (m_device_details == device_details) return;
    m_device_details = device_details;
    emit deviceDetailsChanged();
    save();
}

qint64 Wallet::amountToSats(const QString& amount) const
{
    const auto session = m_context->primarySession();
    return parseAmount(amount, session->unit());
}

qint64 Wallet::parseAmount(const QString& amount, const QString& unit) const
{
    if (!m_context) return 0;
    auto session = m_context->primarySession();
    if (!session) return 0;
    if (amount.isEmpty()) return 0;
    QString sanitized_amount = amount;
    sanitized_amount.replace(',', '.');
    auto details = Json::fromObject({{ unit == "\u00B5BTC" ? "ubtc" : unit.toLower(), sanitized_amount }});
    GA_json* balance;
    int err = GA_convert_amount(session->m_session, details.get(), &balance);
    if (err != GA_OK) return 0;
    QJsonObject result = Json::toObject(balance);
    GA_destroy_json(balance);
    return result.value("sats").toString().toLongLong();
}

void Wallet::updateHashId(const QString& hash_id)
{
    if (m_hash_id == hash_id) return;
    if (!m_hash_id.isEmpty()) {
        qWarning() << Q_FUNC_INFO << "new:" << hash_id << "current:" << m_hash_id;
    }
    m_hash_id = hash_id;
    save();
}

QString Wallet::getDisplayUnit(const QString& unit)
{
    return ComputeDisplayUnit(m_context->primarySession()->network(), unit);
}

void Wallet::resetLoginAttempts()
{
    if (m_login_attempts_remaining < 3) {
        m_login_attempts_remaining = 3;
        emit loginAttemptsRemainingChanged();
        save();
    }
}

void Wallet::decrementLoginAttempts()
{
    Q_ASSERT(m_login_attempts_remaining > 0);
    --m_login_attempts_remaining;
    emit loginAttemptsRemainingChanged();
    if (m_login_attempts_remaining == 0) {
        m_pin_data.clear();
        emit hasPinDataChanged();
    }
    save();
}

void Wallet::setXPubHashId(const QString &xpub_hash_id)
{
    if (m_xpub_hash_id == xpub_hash_id) return;
    Q_ASSERT(m_xpub_hash_id.isEmpty());
    m_xpub_hash_id = xpub_hash_id;
    save();
}
