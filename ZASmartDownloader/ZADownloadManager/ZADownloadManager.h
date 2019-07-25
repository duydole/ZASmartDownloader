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
@property (nonatomic) NSInteger maxConcurrentDownloads;

@property (nonatomic) NSUInteger timeoutIntervalForRequest;

@property (nonatomic, readonly) NSUInteger numberOfDownloadingUrls;

/**
 @brief get default directory url, which downloaded files is stored.
 */
- (NSURL*) getDefaultDownloadedFileDirectoryUrl;

/**
 @brief get default directory url, which downloaded files is stored.
 */
- (NSURL*) getDefaultDownloadedImageDirectoryUrl;

// download a file with RequestItem, retryCount, retryInterval.
- (void) downloadFileWithRequestItem:(ZARequestItem*)requestItem
                          retryCount:(NSUInteger)retryCount
                       retryInterval:(NSUInteger)retryInterval;

// download a file with requestItem:
// Default: Retry count = 3, retryInterval = 10;
- (void) downloadFileWithRequestItem:(ZARequestItem*)requestItem;

// download a file with url:
- (ZARequestItem*) downloadFileWithURL:(NSString*)urlString
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
- (void) pauseDownloadingOfRequest:(ZARequestItem*)requestItem;

/**
@brief resume a paused downloadtask or failed tasks (loss connection).
 */
- (void) resumeDownloadingOfRequest:(ZARequestItem*)requestItem;

/**
 @brief resume a paused downloadtask or failed tasks (loss connection).
 */
- (void) retryDownloadingOfRequestItem:(ZARequestItem*)requestItem;

/**
 @brief cancel a downlading file with requestItem.
 */
- (void) cancelDownloadingOfRequest:(ZARequestItem*)requestItem;

@end
