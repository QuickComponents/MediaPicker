# MediaPicker
Image and video media picker

#### Clone project
```bash
git clone https://github.com/QuickComponents/MediaPicker.git plugins/MediaPicker
```

#### Include module in *.pro or *.pri file
```pro
include($$PWD/plugins/MediaPicker/MediaPicker.pri)
```

#### Configure main.cpp
```cpp
engine.addImportPath("qrc:///");
```

#### Use in QML
```qml
import QuickComponents 1.0

...

MediaPicker {
    id: mediaPicker
    contentType: MediaPicker.Image // or MediaPicker.Video
}

