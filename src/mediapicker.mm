#include "mediapicker.h"
#include <QCoreApplication>
#include <QUrl>
#include <QImage>

#import <UIKit/UIKit.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <MobileCoreServices/UTCoreTypes.h>
#import <Photos/Photos.h>

@interface QiOSViewDelegate: UIImagePickerController<UIImagePickerControllerDelegate, UINavigationControllerDelegate>
- (instancetype) initQiOSViewDelegate:(MediaPickerPlugin *) mediaPicker;
- (void) alertMessage:(NSString *) message;
@end

@implementation QiOSViewDelegate
{
    MediaPickerPlugin *m_mediaPicker;
    UIViewController *m_viewController;
    UIWindow *m_rootWindow;
}

- (instancetype) initQiOSViewDelegate:(MediaPickerPlugin *) mediaPicker
{
    m_mediaPicker = mediaPicker;

    m_rootWindow = [UIApplication sharedApplication].keyWindow;
    m_viewController = m_rootWindow.rootViewController;

    UIImagePickerControllerSourceType sourceType = m_mediaPicker->sourceType() ? UIImagePickerControllerSourceTypeCamera : UIImagePickerControllerSourceTypePhotoLibrary;
    if (![UIImagePickerController isSourceTypeAvailable: sourceType]) {
        [self alertMessage:@"This operation is not supported in this device"];
        return self;
    }

    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.sourceType = sourceType;

    picker.editing = NO;
    picker.mediaTypes = [NSArray arrayWithObject:(NSString *) kUTTypeImage];
    if (m_mediaPicker->contentType() == MediaPickerPlugin::Video) {
        picker.mediaTypes = @[(NSString *) kUTTypeMovie, (NSString *) kUTTypeAVIMovie, (NSString *) kUTTypeVideo, (NSString *) kUTTypeMPEG4];
        picker.videoQuality = UIImagePickerControllerQualityTypeHigh;
    }

    picker.delegate = self;
    [m_viewController presentViewController:picker animated:YES completion:nil];

    return self;
}

- (void) imagePickerController:(UIImagePickerController *) picker didFinishPickingMediaWithInfo:(NSDictionary *) info
{
    Q_UNUSED(picker);
    [m_viewController dismissViewControllerAnimated:YES completion:nil];

    NSURL *url = nil;
    if (m_mediaPicker->sourceType() == MediaPickerPlugin::Camera) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDirectory, YES);
        NSString *documentsDirectory = [paths firstObject];
        NSString *fullPath = nil;
        NSFileManager *fileManager = [NSFileManager defaultManager];

        if ([info[UIImagePickerControllerMediaType]  isEqual: @"public.movie"]) {
            NSURL *videoUrl = info[UIImagePickerControllerMediaURL];
            fullPath = [[documentsDirectory stringByAppendingPathComponent:[[NSUUID UUID] UUIDString]] stringByAppendingPathExtension:@"mov"];

            [fileManager moveItemAtPath:[videoUrl path] toPath:fullPath error:nil];
        } else {
            UIImage *image = info[UIImagePickerControllerOriginalImage];
            NSData *imageData = UIImageJPEGRepresentation(image, 1.0);
            fullPath = [[documentsDirectory stringByAppendingPathComponent:[[NSUUID UUID] UUIDString]] stringByAppendingPathExtension:@"jpg"];

            [fileManager createFileAtPath:fullPath contents:imageData attributes:nil];
        }
        url = [[NSURL alloc] initFileURLWithPath:fullPath];
    } else {
        if ([info[UIImagePickerControllerMediaType]  isEqual: @"public.movie"]) {
            url = info[UIImagePickerControllerMediaURL];
        } else {
            if (@available(iOS 11.0, *))
                url = info[UIImagePickerControllerImageURL];
            else
                url = info[UIImagePickerControllerReferenceURL];
        }
    }
    if (url) {
        QUrl fileUrl = QString::fromNSString(url.description);
        m_mediaPicker->setFileUrls(QList<QUrl>() << fileUrl);
    }
}

- (void) alertMessage:(NSString *) message
{
    UIAlertController *alert = [
            UIAlertController
            alertControllerWithTitle:@"Error"
            message:message
            preferredStyle:UIAlertControllerStyleAlert
    ];
    [
        alert addAction:[
            UIAlertAction
            actionWithTitle:NSLocalizedString(@"OK",@"Confirm")
            style:UIAlertActionStyleCancel handler:^(UIAlertAction *_Nonnull action) { Q_UNUSED(action) }
        ]
    ];
    [m_rootWindow makeKeyAndVisible];
    [m_viewController presentViewController:alert animated:YES completion:nil];
}

@end

void MediaPickerPlugin::open()
{
    [[QiOSViewDelegate alloc] initQiOSViewDelegate:this];
}
