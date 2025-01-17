import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import QtQuick.Shapes

Popup {
    signal codeScanned(string code)

    id: self
    background: null
    x: parent.width / 2 - width / 2
    y: -height + parent.height / 2
    contentItem: Loader {
        active: self.visible
        sourceComponent: Item {
            implicitWidth: 300
            implicitHeight: 200
            DropShadow {
                opacity: 0.5
                verticalOffset: 8
                radius: 32
                samples: 16
                source: bg
                anchors.fill: parent
            }
            Shape {
                id: bg
                anchors.fill: parent
                layer.samples: 4
                PopupBalloon {
                    strokeWidth: 0
                    fillColor: constants.c700
                }
            }
            ScannerView {
                id: scanner_view
                anchors.fill: parent
                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: Shape {
                        width: scanner_view.width
                        height: scanner_view.height
                        PopupBalloon {
                            strokeWidth: 1
                            strokeColor: 'transparent'
                            fillColor: 'white'
                        }
                    }
                }
                onCodeScanned: (code) => {
                    self.codeScanned(code)
                    self.close()
                }
            }
            Shape {
                anchors.fill: parent
                layer.samples: 4
                PopupBalloon {
                    strokeColor: '#343842'
                    strokeWidth: 1
                    fillColor: 'transparent'
                }
            }
            CloseButton {
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.margins: 20
                onClicked: self.close()
            }
        }
    }
}
