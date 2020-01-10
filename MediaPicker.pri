CONFIG += c++11
INCLUDEPATH += $$PWD

QT += multimedia

android {
    QT += androidextras

    HEADERS += \
        $$PWD/src/mediapicker.h

    SOURCES += \
        $$PWD/src/mediapicker.cpp
} else: ios {
    LIBS += -framework Foundation -framework UIKit -framework Photos

    HEADERS += \
        $$PWD/src/mediapicker.h

    OBJECTIVE_SOURCES += \
        $$PWD/src/mediapicker.mm
} else {
    RESOURCES += \
        $$PWD/MediaPicker.qrc
}
