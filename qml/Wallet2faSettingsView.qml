import Blockstream.Green
import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    id: self
    required property Context context
    required property Wallet wallet
    required property Session session

    spacing: 16

    Controller {
        id: controller
        context: self.context
    }

    SettingsBox {
        title: qsTrId('id_twofactor_authentication')
        enabled: !self.context.locked
        contentItem: ColumnLayout {
            Layout.fillWidth: true
            spacing: 8
            Label {
                Layout.fillWidth: true
                text: qsTrId('id_enable_twofactor_authentication')
                wrapMode: Text.WordWrap
            }
            Repeater {
                model: {
                    const methods = self.session.config.all_methods || []
                    return methods.filter(method => {
                        switch (method) {
                            case 'email': return true
                            case 'sms': return true
                            case 'phone': return true
                            case 'gauth': return true
                            case 'telegram': return true
                            default: return false
                        }
                    })
                }

                RowLayout {
                    Layout.fillWidth: true

                    property string method: modelData

                    Image {
                        source: `qrc:/svg/2fa_${method}.svg`
                        sourceSize.height: 32
                    }
                    ColumnLayout {
                        Label {
                            text: {
                                switch (method) {
                                    case 'email':
                                        return qsTrId('id_email')
                                    case 'sms':
                                        return qsTrId('id_sms')
                                    case 'phone':
                                        return qsTrId('id_phone_call')
                                    case 'gauth':
                                        return qsTrId('id_authenticator_app')
                                    case 'telegram':
                                        return qsTrId('id_telegram')
                                }
                            }
                        }
                        Label {
                            visible: self.session.config[method].enabled
                            text: method === 'gauth' ? qsTrId('id_enabled') : self.session.config[method].data
                            color: constants.c100
                            font.pixelSize: 10
                            font.weight: 400
                            font.styleName: 'Regular'
                        }
                    }
                    HSpacer {
                    }
                    GSwitch {
                        Binding on checked {
                            value: self.session.config[method].enabled
                        }

                        onClicked: {
                            checked = self.session.config[modelData].enabled;
                            if (!self.session.config[method].enabled) {
                                enable_dialog.createObject(stack_view, { method }).open();
                            } else {
                                disable_dialog.createObject(stack_view, { method }).open();
                            }
                        }
                    }
                }
            }
        }
    }

    SettingsBox {
        title: qsTrId('id_set_twofactor_threshold')
        enabled: !self.context.locked
        visible: !wallet.network.liquid && !!self.session.config.limits
        contentItem: RowLayout {
            Label {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                text: qsTrId('id_set_a_limit_to_spend_without')
                wrapMode: Text.WordWrap
            }
            GButton {
                large: false
                text: qsTrId('id_change')
                onClicked: set_twofactor_threshold_dialog.createObject(stack_view).open()
                Layout.alignment: Qt.AlignRight
            }
        }
    }

    SettingsBox {
        title: qsTrId('id_twofactor_authentication_expiry')
        visible: !wallet.network.liquid
        contentItem: RowLayout {
            Label {
                Layout.fillWidth: true
                text: qsTrId('id_customize_2fa_expiration_of')
                wrapMode: Text.WordWrap
            }
            GButton {
                Layout.alignment: Qt.AlignRight
                large: false
                text: qsTrId('id_change')
                onClicked: two_factor_auth_expiry_dialog.createObject(stack_view).open()
            }
        }
    }

    SettingsBox {
        title: qsTrId('id_request_twofactor_reset')
        contentItem: RowLayout {
            Label {
                Layout.fillWidth: true
                text: self.context.locked ? qsTrId('wallet locked for %1 days').arg(self.session.config.twofactor_reset ? self.session.config.twofactor_reset.days_remaining : 0) : qsTrId('id_start_a_2fa_reset_process_if')
                wrapMode: Text.WordWrap
            }
            GButton {
                large: false
                Layout.alignment: Qt.AlignRight
                enabled: self.session.config.any_enabled || false
                text: self.context.locked ? qsTrId('id_cancel_twofactor_reset') : qsTrId('id_reset')
                Component {
                    id: cancel_dialog
                    CancelTwoFactorResetDialog { }
                }

                Component {
                    id: request_dialog
                    RequestTwoFactorResetDialog {
                    }
                }
                onClicked: {
                    if (self.context.locked) {
                        cancel_dialog.createObject(stack_view, { wallet }).open()
                    } else {
                        request_dialog.createObject(stack_view, { wallet }).open()
                    }
                }
            }
        }
    }

    Component {
        id: enable_dialog
        TwoFactorEnableDialog {
            wallet: self.wallet
            session: self.session
        }
    }

    Component {
        id: disable_dialog
        TwoFactorDisableDialog {
            wallet: self.wallet
            session: self.session
        }
    }

    Component {
        id: set_twofactor_threshold_dialog
        TwoFactorLimitDialog {
            wallet: self.wallet
            session: self.session
        }
    }

    Component {
        id: two_factor_auth_expiry_dialog
        TwoFactorAuthExpiryDialog {
            wallet: self.wallet
            session: self.session
        }
    }
}
