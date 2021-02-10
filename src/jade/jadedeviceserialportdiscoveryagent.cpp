#include "jadedeviceserialportdiscoveryagent.h"

#include <QTimer>
#include <QSerialPortInfo>

#include "jadeapi.h"
#include "jadedevice.h"
#include "wallet.h"
#include "walletmanager.h"
#include "network.h"
#include "networkmanager.h"

#include "resolver.h"
#include "handlers/connecthandler.h"
#include "handlers/loginhandler.h"
#include "handlers/registeruserhandler.h"

#include <gdk.h>
#include "json.h"

#include <wally_bip32.h>

static QJsonObject device_details_from_device()
{
    return {{
        "device", QJsonObject({
            { "name", "JADE" },
            { "supports_arbitrary_scripts", true },
            { "supports_low_r", true },
            { "supports_liquid", 1 }
        })
    }};
}

#include "devicemanager.h"

JadeDeviceSerialPortDiscoveryAgent::JadeDeviceSerialPortDiscoveryAgent(QObject* parent)
    : QObject(parent)
{
    auto timer = new QTimer(this);
    connect(timer, &QTimer::timeout, [this] {
        auto devices = m_devices;
        m_devices.clear();

        for (const auto &info : QSerialPortInfo::availablePorts()) {
            const auto system_location = info.systemLocation();
            auto device = devices.take(system_location);
            if (!device) {
    #ifdef Q_OS_MACOS
                if (!info.systemLocation().startsWith("/dev/cu.usbserial")) continue;
    #else
                // Q_UNIMPLEMENTED();
    #endif
                const auto product_id = QByteArray::number(info.productIdentifier(), 16);
                if (product_id != "ea60") continue;
                const auto vendor_id = QByteArray::number(info.vendorIdentifier(), 16);
                if (vendor_id != "10c4") continue;
    #ifdef Q_OS_WIN
                if (info.description() != "Silicon Labs CP210x USB to UART Bridge") continue;
    #else
                if (info.description() != "CP2104 USB to UART Bridge Controller") continue;
    #endif
                if (info.manufacturer() != "Silicon Labs") continue;

                auto api = new JadeAPI(info);
                device = new JadeDevice(api, this);
                api->setParent(device);
                device->m_system_location = system_location;
                connect(api, &JadeAPI::onConnected, this, [this, device] {
                    qDebug() << "JadeAPI::onConnected";
                    device->m_jade->getVersionInfo([this, device](const QVariantMap& data) {
                        const auto result = data.value("result").toMap();
                        device->setVersionInfo(result);
                        device->m_name = QString("Jade %1").arg(result.value("JADE_VERSION").toString());
                        DeviceManager::instance()->addDevice(device);
                    });
                });
                connect(api, &JadeAPI::onDisconnected, this, [this, device] {
                    qDebug() << "JadeAPI::onDisconnected";
                });
                api->connectDevice();
                qDebug() << "Attach device at" << system_location;
                m_devices.insert(system_location, device);
            } else if (device->m_jade->isConnected()) {
                m_devices.insert(system_location, device);
            } else {
                devices.insert(system_location, device);
            }
        }

        if (devices.empty()) return;

        // TODO: delete disconnected devices
        while (!devices.empty()) {
            const auto system_location = devices.firstKey();
            qDebug() << "Dettach device at" << system_location;
            auto device = devices.take(system_location);
            DeviceManager::instance()->removeDevice(device);
            device->m_jade->disconnectDevice();
            delete device;
        }

        qDebug() << "Attached devices" << m_devices.size();
    });
    timer->start(1000);
}

void JadeController::setNetwork(const QString& network)
{
    if (m_network == network) return;
    m_network = network;
    emit networkChanged(m_network);
}

void JadeController::login()
{
    Q_ASSERT(m_device);
    auto network = NetworkManager::instance()->network(m_network);
    Q_ASSERT(network);
    Q_ASSERT(!m_wallet);

    m_wallet = new Wallet;
    m_wallet->m_id = m_device->uuid();
    m_wallet->m_device = m_device;
    m_wallet->setNetwork(network);
    m_wallet->createSession();

    walletChanged(m_wallet);

    auto device_details = device_details_from_device();
    auto connect_handler = new ConnectHandler(m_wallet);
    auto register_user_handler = new RegisterUserHandler(m_wallet, device_details);
    auto login_handler = new LoginHandler(m_wallet, device_details);
    connect(connect_handler, &Handler::done, this, [this, network, register_user_handler] {
        m_device->m_jade->setHttpRequestProxy([this](JadeAPI& jade, int id, const QJsonObject& req) {
            const auto params = Json::fromObject(req.value("params").toObject());
            GA_json* output;
            GA_http_request(m_wallet->m_session, params.get(), &output);
            auto res = Json::toObject(output);
            GA_destroy_json(output);
            jade.handleHttpResponse(id, req, res.value("body").toObject());
        });
        m_device->m_jade->authUser(network->id(), [register_user_handler](const QVariantMap& msg) {
            Q_ASSERT(msg.contains("result") && msg["result"].toBool());
            register_user_handler->exec();
        });
    });
    connect(register_user_handler, &Handler::done, this, [login_handler] {
        login_handler->exec();
    });
    connect(register_user_handler, &Handler::resolver, this, [](Resolver* resolver) {
        resolver->resolve();
    });
    connect(register_user_handler, &Handler::error, this, []() {
        //setStatus("locked");
    });
    connect(login_handler, &Handler::done, this, [this] {
        m_wallet->setSession();
        WalletManager::instance()->addWallet(m_wallet);
    });
    connect(login_handler, &Handler::resolver, this, [this](Resolver* resolver) {
        connect(resolver, &Resolver::progress, this, [](int current, int total) {
//                                    m_progress = current == total ? 0 : qreal(current) / qreal(total);
//                                    emit progressChanged(m_progress);
        });
        resolver->resolve();
    });
    connect(login_handler, &Handler::error, this, []() {
        //setStatus("locked");
    });
    connect_handler->exec();
}

JadeController::JadeController(QObject* parent)
    : QObject(parent)
{

}

void JadeController::setDevice(JadeDevice* device)
{
    if (m_device == device) return;
    m_device = device;
    emit deviceChanged(m_device);
}