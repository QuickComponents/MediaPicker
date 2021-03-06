#ifndef FILEDIALOGNATIVEPLUGIN_H
#define FILEDIALOGNATIVEPLUGIN_H

#include <QQuickItem>
#include <QObject>
#include <QList>
#include <QUrl>

#if defined (Q_OS_ANDROID)
#include <QtAndroidExtras>
#endif

#if defined (Q_OS_ANDROID)
class MediaPickerPlugin : public QQuickItem, public QAndroidActivityResultReceiver
#else
class MediaPickerPlugin : public QQuickItem
#endif
{
    Q_OBJECT
    Q_PROPERTY(quint16 contentType READ contentType WRITE setContentType NOTIFY contentTypeChanged)
    Q_PROPERTY(bool selectMultiple READ selectMultiple WRITE setSelectMultiple NOTIFY selectMultipleChanged)
    Q_PROPERTY(QList<QUrl> fileUrls READ fileUrls WRITE setFileUrls NOTIFY fileUrlsChanged)
    Q_PROPERTY(QUrl fileUrl READ fileUrl WRITE setFileUrl NOTIFY fileUrlsChanged)

public:
    explicit MediaPickerPlugin(QQuickItem *parent = nullptr) :
        QQuickItem(parent), m_contentType(0), m_selectMultiple(false) {}

    Q_INVOKABLE void open();

#if defined (Q_OS_ANDROID)
    virtual void handleActivityResult(int receiverRequestCode, int resultCode, const QAndroidJniObject &data) override;
#endif

    enum ContentType {
        Image,
        Video
    };
    Q_ENUM(ContentType)
    enum SourceType {
        Library,
        Camera
    };
    Q_ENUM(SourceType);

    inline quint16 contentType() { return m_contentType; }
    inline void setContentType(quint16 content_type) { m_contentType = content_type; emit contentTypeChanged(); }

    inline bool selectMultiple() { return m_selectMultiple; }
    inline void setSelectMultiple(bool multiple) { m_selectMultiple = multiple; emit selectMultipleChanged(); }

    inline QList<QUrl> fileUrls() const { return m_fileUrls; }
    inline void setFileUrls(QList<QUrl> urls) { m_fileUrls.clear(); m_fileUrls = urls; emit fileUrlsChanged(); }

    inline QUrl fileUrl() const { return m_fileUrls.at(0); }
    inline void setFileUrl(QUrl url) { m_fileUrls.clear(); m_fileUrls.append(url); emit fileUrlsChanged(); }

signals:
    void contentTypeChanged();
    void selectMultipleChanged();
    void fileUrlsChanged();

public slots:

private:
    quint16 m_contentType;
    bool m_selectMultiple;
    QList<QUrl> m_fileUrls;

};

#endif // FILEDIALOGNATIVEPLUGIN_H

static void registerFileDialogNative()
{
    qmlRegisterType<MediaPickerPlugin>("QuickComponents", 1, 0, "MediaPicker");
}

Q_COREAPP_STARTUP_FUNCTION(registerFileDialogNative)
