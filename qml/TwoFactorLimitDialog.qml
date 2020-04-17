import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.5
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.12

ControllerDialog {
    property var currencies: [{
        is_fiat: false,
        text: wallet.settings.unit
    }, {
        is_fiat: true,
        text: wallet.settings.pricing.currency
    }]

    property string threshold: wallet.config.limits.is_fiat ? wallet.config.limits.fiat : wallet.config.limits[wallet.settings.unit.toLowerCase()]
    property string ticker: wallet.config.limits.is_fiat ? wallet.settings.pricing.currency : wallet.settings.unit

    title: qsTr('id_set_twofactor_threshold')
    doneText: qsTr('id_your_twofactor_threshold_is_s').arg(threshold + ' ' +  ticker)
    width: 400
    height: 250
    controller: TwoFactorController { }
    initialItem: WizardPage {
        actions: Action {
            text: qsTr('id_next')
            onTriggered: controller.changeLimit(currency_combo.fiat, amount_field.text)
        }

        GridLayout {
            columns: 2
            anchors.fill: parent

            Label {
                text: qsTr('id_currency')
            }

            ComboBox {
                property bool fiat: model[currentIndex].is_fiat
                id: currency_combo
                currentIndex: wallet.config.limits.is_fiat ? 1 : 0
                flat: true
                model: currencies
                textRole: 'text'
                Layout.fillWidth: true
            }

            Label {
                text: qsTr('id_amount')
            }

            TextField {
                id: amount_field
                text: threshold
                padding: 10
                Layout.fillWidth: true
            }
            Item {
                Layout.fillHeight: true
            }
        }
    }
}