#include "mediapicker.h"
#include <QDebug>

static const int PICK_FILE = 0xFFF;

const QString getUriFromJniObject(QAndroidJniObject &uri);

void MediaPickerPlugin::open()
{
    // or GET_CONTENT error of permission
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

        QtAndroid::startActivity(intent.object<jobject>(), PICK_FILE, this);
    }
}

void MediaPickerPlugin::handleActivityResult(int receiverRequestCode, int resultCode, const QAndroidJniObject &data)
{
    jint RESULT = QAndroidJniObject::getStaticField<jint>("android/app/Activity", "RESULT_OK");
    if (receiverRequestCode == PICK_FILE && resultCode == RESULT) {
        QList<QUrl> urls;
        if (m_selectMultiple && QtAndroid::androidSdkVersion() >= 19) {
            QAndroidJniObject clipData = data.callObjectMethod("getClipData","()Landroid/content/ClipData;");
            qWarning() << "ClipData" << clipData.toString() << clipData.isValid();
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

        if (!cursor.callMethod<jboolean>("isClosed"))
            cursor.callObjectMethod("close", "()Z");

        if (path.isValid())
            return QString("file://%1").arg(path.toString());
    }

    return QString();
}
