import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Pane {
    required property Context context
    required property Account currentAccount

    id: self
    clip: true
    padding: 16
    background: Rectangle {
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.04)
        color: Qt.alpha('#161921', 0.2)
        radius: 8
    }
    contentItem: Flickable {
        id: flickable
        implicitHeight: layout.implicitHeight
        contentWidth: layout.implicitWidth
        RowLayout {
            id: layout
            TotalBalanceCard {
                context: self.context
                account: self.currentAccount
            }
            Separator {
            }
            AssetsCard {
                context: self.context
                onClicked: assets_drawer.open()
            }
            Separator {
            }
            PriceCard {
                context: self.context
                account: self.currentAccount
            }
            Separator {
            }
            FeeRateCard {
                context: self.context
            }
        }
    }
    Image {
        source: 'qrc:/svg2/arrow_right.svg'
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        visible: flickable.contentX > 0
        rotation: 180
    }
    Image {
        source: 'qrc:/svg2/arrow_right.svg'
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        visible: flickable.contentWidth - flickable.contentX > flickable.width
    }

    component Separator: Item {
        Layout.minimumWidth: 41
        Layout.maximumWidth: 41
        Layout.fillHeight: true
        Rectangle {
            opacity: 0.04
            width: 1
            height: parent.height
            anchors.centerIn: parent
        }
    }
}
