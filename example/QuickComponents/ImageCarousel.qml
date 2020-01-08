import QtQuick 2.14
import QtQuick.Controls 2.14

Column {
    id: root
    width: parent.width

    property alias model: repeater.model

    PageIndicator {
        anchors.horizontalCenter: parent.horizontalCenter
        currentIndex: swipeView.currentIndex
        count: swipeView.count
    }

    SwipeView {
        id: swipeView
        width: parent.width

        Repeater {
            id: repeater

            Pane {
                Image {
                    sourceSize.width: root.width > 500 ? 500 : root.width
                    anchors.horizontalCenter: parent.horizontalCenter
                    source: Qt.resolvedUrl(modelData)
                }
            }
        }
    }
}
