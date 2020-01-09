#include "mediapicker.h"
#include <QDebug>
#include <QDateTime>
#include <QStandardPaths>

static const int PICK = 0xFFF;
static const int CAPTURE = 0x1;

const QString getUriFromJniObject(QAndroidJniObject &uri);

void MediaPickerPlugin::open()
{
    if (m_sourceType == MediaPickerPlugin::Library) {
        actionPick();
        return;
    }

    if (m_contentType == MediaPickerPlugin::Image)
        actionCameraPicture();
    else
        actionCameraMovie();
}


void MediaPickerPlugin::actionPick()
{
    // or GET_CONTENT: error of permission
    QAndroidJniObject ACTION_PICK = QAndroidJniObject::fromString("android.intent.action.PICK");
    QAndroidJniObject intent("android/content/Intent");
    if (ACTION_PICK.isValid() && intent.isValid()) {
        QString content;
        switch (m_contentType) {
        case MediaPickerPlugin::Image: content = "image/*"; break;
        case MediaPickerPlugin::Video: content = "video/*"; break;
        }

        if (m_selectMultiple && QtAndroid::androidSdkVersion() >= 19) {
            intent.callObjectMethod("putExtra","(Ljava/lang/String;Z)Landroid/content/Intent;",
                                    QAndroidJniObject::getStaticObjectField("android/content/Intent",
                                                                            "EXTRA_ALLOW_MULTIPLE",
                                                                            "Ljava/lang/String;").object<jobject>(), true);
        }

        intent.callObjectMethod("setAction", "(Ljava/lang/String;)Landroid/content/Intent;",
                                ACTION_PICK.object<jstring>());
        intent.callObjectMethod("setType", "(Ljava/lang/String;)Landroid/content/Intent;",
                                QAndroidJniObject::fromString(content).object<jstring>());

        QtAndroid::startActivity(intent.object<jobject>(), PICK, [this](int receiverRequestCode, int resultCode, const QAndroidJniObject &data) {
            jint RESULT = QAndroidJniObject::getStaticField<jint>("android/app/Activity", "RESULT_OK");
            if (receiverRequestCode == PICK && resultCode == RESULT) {
                QList<QUrl> urls;
                if (m_selectMultiple && QtAndroid::androidSdkVersion() >= 19) {
                    QAndroidJniObject clipData = data.callObjectMethod("getClipData","()Landroid/content/ClipData;");
                    if (clipData.isValid()) {
                        int clipDataTotal = clipData.callMethod<jint>("getItemCount");
                        for (int i = 0; i < clipDataTotal; ++i) {
                            QAndroidJniObject item = clipData.callObjectMethod("getItemAt", "(I)Landroid/content/ClipData$Item;", i);
                            QAndroidJniObject uri = item.callObjectMethod("getUri", "()Landroid/net/Uri;");
                            QUrl url = QUrl(getUriFromJniObject(uri));
                            urls.append(url);
                        }
                        setFileUrls(urls);
                        return;
                    }
                }
                QAndroidJniObject uri = data.callObjectMethod("getData", "()Landroid/net/Uri;");
                QUrl url = QUrl(getUriFromJniObject(uri));
                urls.append(url);
                setFileUrls(urls);
            }
        });
    }
}

void MediaPickerPlugin::actionCameraPicture()
{
    QAndroidJniObject ACTION = QAndroidJniObject::fromString("android.media.action.IMAGE_CAPTURE");
    QAndroidJniObject intent("android/content/Intent");

    if (ACTION.isValid() && intent.isValid()) {
        intent.callObjectMethod("setAction", "(Ljava/lang/String;)Landroid/content/Intent;",
                                ACTION.object<jstring>());

        QAndroidJniObject EXTRA_OUTPUT = QAndroidJniObject::getStaticObjectField("android/provider/MediaStore", "EXTRA_OUTPUT", "Ljava/lang/String;");
        QAndroidJniObject DIR_PICUTRES = QAndroidJniObject::getStaticObjectField<jstring>("android.os.Environment", "DIRECTORY_PICTURES");
        QAndroidJniObject EXT_DIR = QAndroidJniObject::callStaticObjectMethod("android/os/Environment", "getExternalStoragePublicDirectory", "(Ljava/lang/String;)Ljava/io/File;", DIR_PICUTRES.object());
        QAndroidJniObject FILENAME = QAndroidJniObject::fromString(QString("%1.JPG").arg(QDateTime::currentDateTime().toString("yyyyMMdd-hhmmss")));
        QAndroidJniObject FILE = QAndroidJniObject("java/io/File","(Ljava/io/File;Ljava/lang/String;)V", EXT_DIR.object<jobject>(), FILENAME.object<jstring>());
        QAndroidJniObject uri = QAndroidJniObject::callStaticObjectMethod("android/net/Uri", "fromFile", "(Ljava/io/File;)Landroid/net/Uri;", FILE.object<jobject>());
        intent.callObjectMethod("putExtra","(Ljava/lang/String;Landroid/os/Parcelable;)Landroid/content/Intent;",
                                EXTRA_OUTPUT.object<jstring>(), uri.object<jobject>());

        QtAndroid::startActivity(intent.object<jobject>(), CAPTURE,
        [this, uri](int receiverRequestCode, int resultCode, const QAndroidJniObject &data) {
            Q_UNUSED(data)
            jint RESULT = QAndroidJniObject::getStaticField<jint>("android/app/Activity", "RESULT_OK");
            if (receiverRequestCode == CAPTURE && resultCode == RESULT) {
                QUrl url = QUrl(uri.toString());
                setFileUrls(QList<QUrl>() << url);
            }
        });
    }
}

void MediaPickerPlugin::actionCameraMovie()
{
    QAndroidJniObject ACTION = QAndroidJniObject::fromString("android.media.action.VIDEO_CAPTURE");
    QAndroidJniObject intent("android/content/Intent");

    if (ACTION.isValid() && intent.isValid()) {
        intent.callObjectMethod("setAction", "(Ljava/lang/String;)Landroid/content/Intent;",
                                ACTION.object<jstring>());
        QtAndroid::startActivity(intent.object<jobject>(), CAPTURE,
        [this](int receiverRequestCode, int resultCode, const QAndroidJniObject &data) {
            Q_UNUSED(this)
            jint RESULT = QAndroidJniObject::getStaticField<jint>("android/app/Activity", "RESULT_OK");
            if (receiverRequestCode == CAPTURE && resultCode == RESULT) {
                QAndroidJniObject uri = data.callObjectMethod("getData", "()Landroid/net/Uri;");
                QUrl url = QUrl(getUriFromJniObject(uri));
                setFileUrls(QList<QUrl>() << url);
            }
        });
    }
}

const QString getUriFromJniObject(QAndroidJniObject &uri) {
    if (uri.toString().startsWith("file://"))
        return uri.toString();

    QAndroidJniEnvironment env;
    QAndroidJniObject media = QAndroidJniObject::getStaticObjectField("android/provider/MediaStore$MediaColumns", "DATA", "Ljava/lang/String;");

    jobjectArray projection = (jobjectArray)env->NewObjectArray(1, env->FindClass("java/lang/String"), env->NewStringUTF(""));
    env->SetObjectArrayElement(projection, 0, media.object<jstring>());

    QAndroidJniObject contentResolver = QtAndroid::androidActivity().callObjectMethod("getContentResolver", "()Landroid/content/ContentResolver;");
    QAndroidJniObject cursor = contentResolver.callObjectMethod("query",
                                                                "(Landroid/net/Uri;[Ljava/lang/String;Ljava/lang/String;[Ljava/lang/String;Ljava/lang/String;)Landroid/database/Cursor;",
                                                                uri.object<jobject>(), projection, NULL, NULL, NULL);

    if (cursor.isValid()) {
        cursor.callMethod<jboolean>("moveToFirst");
        jint columnIndex = cursor.callMethod<jint>("getColumnIndexOrThrow","(Ljava/lang/String;)I", media.object<jstring>());
        QAndroidJniObject path = cursor.callObjectMethod("getString", "(I)Ljava/lang/String;", columnIndex);

//        if (!cursor.callMethod<jboolean>("isClosed"))
//            cursor.callObjectMethod("close", "()Z");

        if (path.isValid())
            return QString("file://%1").arg(path.toString());
    }

    return QString();
}
