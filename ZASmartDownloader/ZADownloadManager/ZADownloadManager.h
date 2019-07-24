#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import "ZACommonDownloadItem.h"
#import <UIKit/UIKit.h>

typedef NSString* DownloadRequestId;

@interface ZADownloadManager : NSObject

 + (instancetype) sharedInstance;

/**
 * Maximum Concurrent downloadTasks.
 * Defautl: maxConcurrentDownloads = -1, no limit the concurrent downloadtasks.
 */
@property NSInteger maxConcurrentDownloads;

@property NSUInteger timeoutIntervalForRequest;

@property (nonatomic, readonly) NSUInteger numberOfDownloadingUrls;

/**
 @brief get default directory url, which downloaded files is stored.
 */
- (NSURL*) getDefaultDownloadedFileDirectoryUrl;

/**
 @brief get default directory url, which downloaded files is stored.
 */
- (NSURL*) getDefaultDownloadedImageDirectoryUrl;

// download a file with requestItem:
- (void) downloadFileWithRequestItem:(ZADownloadItem*)requestItem;

// download a file with url:
- (ZADownloadItem*) downloadFileWithURL:(NSString*)urlString
                        destinationUrl:(NSURL*)destinationUrl
                  enableBackgroundMode:(BOOL)backgroundMode
                            retryCount:(NSUInteger)retryCount
                         retryInterval:(NSUInteger)timeoutInterval
                              priority:(ZADownloadModelPriroity)priority
                              progress:(ZADownloadProgressBlock)progressBlock
                            completion:(ZADownloadCompletionBlock)completionBlock
                               failure:(ZADownloadErrorBlock)errorBlock;

// download a file with url.
// Default: retrycount = 3, timeoutInterval = 10
- (void) downloadFileWithURL:(NSString*)urlString
               directoryName:(NSString*)directoryName
        enableBackgroundMode:(BOOL)backgroundMode
                    priority:(ZADownloadModelPriroity)priority
                    progress:(ZADownloadProgressBlock)progressBlock
                  completion:(ZADownloadCompletionBlock)completionBlock
                     failure:(ZADownloadErrorBlock)errorBlock;

// download a file with url in BackgroundMode, Medium Prioriy, store in DefaultDirectory.
- (void) downloadFileWithURL:(NSString*)urlString
                    progress:(ZADownloadProgressBlock)progressBlock
                  completion:(ZADownloadCompletionBlock)completionBlock
                     failure:(ZADownloadErrorBlock)errorBlock;

/**
 Download a Image with a UrlString
 
 @param urlString : url of image.
 @param completionBlock : handle the DownloadedImage (image) and Url of image in FileSystem (destinationUrl).
 destinationUrl is nil if image is contained it cache.
 @param errorBlock : handle error when downloading.
 */
- (void) downloadImageWithUrl:(NSString*)urlString
                   completion:(void(^)(UIImage *image, NSURL *destinationUrl))completionBlock
                      failure:(void(^)(NSError* error))errorBlock;

/**
 @brief pause a Downloading Task with URL.
 */
- (void) pauseDownloadingOfRequest:(ZADownloadItem*)requestItem;

/**
@brief resume a paused downloadtask or failed tasks (loss connection).
 */
- (void) resumeDownloadingOfRequest:(ZADownloadItem*)requestItem;

/**
 @brief resume a paused downloadtask or failed tasks (loss connection).
 */
- (void) retryDowloadingOfUrl:(NSString*)urlString;

/**
 @brief cancel a downlading file with urlString.
 */
- (void) cancelDownloadingOfRequest:(ZADownloadItem*)requestItem;

/**
 @brief get current state of a download model.
 */
- (ZADownloadModelState) getDownloadStateOfUrl:(NSString*)urlString;

@end
