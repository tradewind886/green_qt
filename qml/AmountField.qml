import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

TextField {
    id: self

    property string unit: 'sats'

    readonly property var units: ['sats', 'BTC', 'mBTC']

    Layout.fillWidth: true
    topPadding: 22
    bottomPadding: 32
    leftPadding: 15
    rightPadding: self.leftPadding + 7 + unit_label.width
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
            visible: {
                if (self.activeFocus) {
                    switch (self.focusReason) {
                    case Qt.TabFocusReason:
                    case Qt.BacktabFocusReason:
                    case Qt.ShortcutFocusReason:
                        return true
                    }
                }
                return false
            }
        }
    }
    horizontalAlignment: TextInput.AlignRight
    font.pixelSize: 30
    font.weight: 500
    Label {
        id: unit_label
        anchors.right: parent.right
        anchors.rightMargin: self.leftPadding
        anchors.baseline: parent.baseline
        text: self.unit
        color: '#00B45A'
        font.pixelSize: 18
        font.weight: 500
        TapHandler {
            cursorShape: Qt.ArrowCursor
            onTapped: self.unit = self.units[(self.units.indexOf(self.unit) + 1) % units.length]
        }
    }
    Label {
        anchors.right: parent.right
        anchors.rightMargin: self.rightPadding
        anchors.top: parent.baseline
        anchors.topMargin: 8
        text: '0 EUR'
        color: '#FFF'
        opacity: 0.4
        font.pixelSize: 12
        font.weight: 500
    }
}
