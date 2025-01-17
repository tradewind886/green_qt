#ifndef GREEN_LOGINWITHPINCONTROLLER_H
#define GREEN_LOGINWITHPINCONTROLLER_H

#include "green.h"
#include "controller.h"

#include <QObject>
#include <QQmlEngine>

class LoginTask;

class LoginController : public Controller
{
    Q_OBJECT
    Q_PROPERTY(Wallet* wallet READ wallet WRITE setWallet NOTIFY walletChanged)
    QML_ELEMENT
public:
    LoginController(QObject* parent = nullptr);

    Wallet* wallet() const { return m_wallet; }
    void setWallet(Wallet* wallet);

    void login(LoginTask* login_task);
    void login(TaskGroup *group, LoginTask* login_task);
    void loginNetwork(Network* network);
public slots:
    void loginWithPin(const QString& pin);
    void loginWithDevice();
signals:
    void walletChanged();
    void invalidPin();
    void sessionError(const QString& error);
    void loginFinished(Context* context);
    void loginFailed();

private:
    Wallet* m_wallet{nullptr};
};

class DeviceController : public Controller
{
    Q_OBJECT
    Q_PROPERTY(Device* device READ device WRITE setDevice NOTIFY deviceChanged)
    QML_ELEMENT
public:
    DeviceController(QObject* parent = nullptr);
    Device* device() const { return m_device; }
    void setDevice(Device* device);
public slots:
    void bind();
signals:
    void deviceChanged();
    void binded(Context* context);
private:
    Device* m_device{nullptr};
};

class LoadController : public Controller
{
    Q_OBJECT
    QML_ELEMENT
public:
    LoadController(QObject* parent = nullptr);
public slots:
    void load();
signals:
    void loadFinished();
private:
    void loadNetwork(TaskGroup* group, Network* network);
    void loginNetwork(Network* network);
private:
    TaskGroupMonitor* const m_monitor;
};

class PinDataController : public Controller
{
    Q_OBJECT
    QML_ELEMENT
public:
    PinDataController(QObject * parent = nullptr);
public slots:
    void update(const QString& pin);
};

#endif // GREEN_LOGINWITHPINCONTROLLER_H
