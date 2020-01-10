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
- (void) didFinishSaving:(UIImage *) image didFinishSavingWithError:(NSError *) error contextInfo:(void *) contextInfo;
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
        if ([info[UIImagePickerControllerMediaType]  isEqual: @"public.movie"]) {
            url = info[UIImagePickerControllerMediaURL];
            UISaveVideoAtPathToSavedPhotosAlbum([url path], nil, nil, nil);
        } else {
            UIImage *image = info[UIImagePickerControllerOriginalImage];
            UIImageWriteToSavedPhotosAlbum(image, self, @selector(didFinishSaving:didFinishSavingWithError:contextInfo:), nil);
        }
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

- (void) didFinishSaving:(UIImage *) image didFinishSavingWithError:(NSError *) error contextInfo:(void *) contextInfo {
    Q_UNUSED(image)
    Q_UNUSED(error)
    Q_UNUSED(contextInfo)

    /*
    PHFetchOptions *fetchOptions = [[PHFetchOptions alloc] init];
    fetchOptions.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES]];
    PHFetchResult *fetchResult = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeImage options:fetchOptions];
    PHAsset *asset = nil;
    if (fetchResult && fetchResult.count > 0) {
        asset = [fetchResult lastObject];
        NSLog(@"Asset %@", asset.localIdentifier);
    }
    PHImageManager *manager = [PHImageManager defaultManager];
    PHImageRequestOptions *options = [PHImageRequestOptions new];
    options.synchronous = YES;
    options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    options.resizeMode = PHImageRequestOptionsResizeModeNone;
    options.networkAccessAllowed = NO;

    [manager requestImageForAsset:asset targetSize:PHImageManagerMaximumSize contentMode:PHImageContentModeDefault options:options resultHandler:^(UIImage *resultImage, NSDictionary *info){
        NSLog(@"image %@", resultImage);
        NSLog(@"info %@", info);
        NSURL *filePath = [info valueForKeyPath:@"PHImageFileURLKey"];
        NSLog(@"filePath %@", filePath);
    }];
    */

//    get image name
    /*
    NSString *str = @"";
    PHFetchOptions *fetchOptions = [[PHFetchOptions alloc] init];
    fetchOptions.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES]];
    PHFetchResult *fetchResult = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeImage options:fetchOptions];
    if (fetchResult != nil && fetchResult.count > 0) {
        str = [[fetchResult lastObject] filename];
    }
    */

//    get path
//    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSPicturesDirectory, NSUserDomainMask, YES);
//    NSString *partialPath = [paths objectAtIndex:0];
//    NSString *myName = str;
//    NSString *path = [NSString stringWithFormat:@"file://%@/%@", partialPath, myName];

//    QUrl url = QUrl(QString::fromNSString(path));
//    m_mediaPicker->setFileUrls(QList<QUrl>() << url);
}

@end

void MediaPickerPlugin::open()
{
    [[QiOSViewDelegate alloc] initQiOSViewDelegate:this];
}
