import QtQuick 2.14
import QtQuick.Controls 2.14

Page {
    id: page
    property var content

    Flickable {
        anchors.fill: parent
        contentHeight: pane.implicitHeight
        flickableDirection: Flickable.AutoFlickIfNeeded

        Pane {
            id: pane
            width: parent.width
            padding: 0

            contentItem: page.content
        }

        ScrollIndicator.vertical: ScrollIndicator {}
    }
}
