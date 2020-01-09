import QtQuick 2.14
import QtQuick.Controls 2.14

import QuickComponents 1.0

ApplicationWindow {
    visible: true
    width: 640
    height: 480
    title: qsTr("QuickComponents")

    FlickablePage {
        anchors.fill: parent

        content: Column {
            width: parent.width
            spacing: 10
            padding: 10

            Label {
                text: qsTr("Image")
            }

            Row {
                width: parent.width
                spacing: 10

                Button {
                    text: qsTr("Gallery")
                    onClicked: {
                        mediaImagePicker.sourceType = MediaPicker.Library
                        mediaImagePicker.open()
                    }
                }

                Switch {
                    text: qsTr("Select Multiple")
                    onCheckedChanged: mediaImagePicker.selectMultiple = !mediaImagePicker.selectMultiple
                    checked: mediaImagePicker.selectMultiple
                }
            }

            Button {
                text: qsTr("Camera")
                onClicked: {
                    mediaImagePicker.sourceType = MediaPicker.Camera
                    mediaImagePicker.open()
                }
            }

            Label {
                text: `Images Selected: ${JSON.stringify(mediaImagePicker.fileUrls, null, 4)}`
            }

            ImageCarousel {
                width: parent.width - parent.padding * 2
                model: JSON.parse(JSON.stringify(mediaImagePicker.fileUrls))
            }
        }
    }


    MediaPicker {
        id: mediaImagePicker
        contentType: MediaPicker.Image
    }

    MediaPicker {
        id: mediaVideoPicker
        contentType: MediaPicker.Video
    }
}
