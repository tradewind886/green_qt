import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

StackViewPage {
    required property Context context
    required property Address address
    id: self
    title: 'Authenticate Address'
    SignMessageController {
        id: controller
        context: self.context
        address: self.address
        message: text_area.text
        onCleared: stack_view.pop(null)
        onRejected: stack_view.pop(null)
        onAccepted: (signature) => stack_view.push(signature_view, { signature })
    }
    TaskPageFactory {
        monitor: controller.monitor
        target: stack_view
    }
    contentItem: ColumnLayout {
        spacing: 20
        Label {
            Layout.fillWidth: true
            Layout.preferredWidth: 0
            text: self.address.data.address
            font.pixelSize: 14
            font.weight: 400
            horizontalAlignment: Label.AlignHCenter
            opacity: 0.4
            wrapMode: Label.Wrap
        }
        TextArea {
            id: text_area
            Layout.fillWidth: true
            Layout.minimumHeight: 160
            enabled: controller.monitor?.idle ?? true
            topPadding: 14
            bottomPadding: 13
            leftPadding: 15
            background: Rectangle {
                color: '#222226'
                radius: 5
                Rectangle {
                    border.width: 2
                    border.color: '#00B45A'
                    color: 'transparent'
                    radius: 9
                    anchors.fill: parent
                    anchors.margins: -4
                    z: -1
                    opacity: {
                        if (text_area.activeFocus) {
                            switch (self.focusReason) {
                            case Qt.TabFocusReason:
                            case Qt.BacktabFocusReason:
                            case Qt.ShortcutFocusReason:
                                return 1
                            }
                        }
                        return 0
                    }
                }
            }
            font.pixelSize: 14
            font.weight: 500
        }
        GStackView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            id: stack_view
            initialItem: ColumnLayout {
                VSpacer {
                }
                PrimaryButton {
                    Layout.fillWidth: true
                    enabled: controller.valid && (controller.monitor?.idle ?? true)
                    text: 'Sign message'
                    onClicked: controller.sign()
                }
            }
        }
    }

    Component {
        id: signature_view
        ColumnLayout {
            required property string signature
            id: view
            VSpacer {
            }
            Image {
                Layout.alignment: Qt.AlignHCenter
                source: 'qrc:/png/completed.png'
            }
            Label {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                font.pixelSize: 14
                font.weight: 600
                text: 'This is the signature for the message signed by the address for proof of ownership.'
                horizontalAlignment: Label.AlignHCenter
                wrapMode: Label.WordWrap
            }
            Label {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                text: view.signature
                font.pixelSize: 12
                font.weight: 500
                horizontalAlignment: Label.AlignHCenter
                wrapMode: Label.Wrap
            }
            CopyAddressButton {
                Layout.alignment: Qt.AlignCenter
                content: view.signature
                text: qsTrId('id_copy_to_clipboard')
            }
            VSpacer {
            }
        }
    }
}
