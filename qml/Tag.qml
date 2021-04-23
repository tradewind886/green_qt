import QtQuick 2.14
import QtQuick.Controls 2.13

Label {
    id: self
    property color color: constants.c300
    property bool large: false
    text: self.text
    font.pixelSize: 10
    font.styleName: "Medium"
    padding: large ? 8 : 4
    topPadding: large ? 6 : 3
    bottomPadding: large ? 6 : 3
    background: Rectangle {
        id: rectangle
        radius: 4
        color: self.color
    }
}