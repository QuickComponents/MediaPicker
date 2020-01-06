import QtQuick 2.13
import Qt.labs.platform 1.1
import QtQuick.Dialogs 1.3

Item {
    id: root

    property alias fileUrl: fileDialog.fileUrl
    property alias fileUrls: fileDialog.fileUrls
    property alias selectMultiple: fileDialog.selectMultiple
    property int contentType: -1

    enum Type { Image, Video }

    function open() { fileDialog.open() }

    FileDialog {
        id: fileDialog
        folder: root.contentType > 0 ? shortcuts.movies : shortcuts.pictures
        nameFilters: root.contentType > 0 ? ["*.avi *.mpg *.mp4 *.mov *mkv"] : ["*.jpg *.jpeg *.png *.gif *.bmp"]
    }
}
