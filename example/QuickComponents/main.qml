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
                width: parent.width
                text: `Images Selected: ${JSON.stringify(mediaImagePicker.fileUrls, null, 4)}`
                wrapMode: Label.WordWrap
            }

            ImageCarousel {
                width: parent.width - parent.padding * 2
                model: JSON.parse(JSON.stringify(mediaImagePicker.fileUrls))
            }

            Label {
                text: qsTr("Video")
            }

            Row {
                width: parent.width
                spacing: 10

                Button {
                    text: qsTr("Gallery")
                    onClicked: {
                        mediaVideoPicker.sourceType = MediaPicker.Library
                        mediaVideoPicker.open()
                    }
                }

                Switch {
                    text: qsTr("Select Multiple")
                    onCheckedChanged: mediaVideoPicker.selectMultiple = !mediaVideoPicker.selectMultiple
                    checked: mediaVideoPicker.selectMultiple
                }
            }

            Button {
                text: qsTr("Camera")
                onClicked: {
                    mediaVideoPicker.sourceType = MediaPicker.Camera
                    mediaVideoPicker.open()
                }
            }

            Label {
                text: `Videos Selected: ${JSON.stringify(mediaVideoPicker.fileUrls, null, 4)}`
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
