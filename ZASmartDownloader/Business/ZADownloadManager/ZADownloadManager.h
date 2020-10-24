//
//  ZASmartDownloader.h
//  ZASmartDownloader
//
//  Created by Do Le Duy on 10/21/20.
//  Copyright © 2020 vng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import "ZACommonDownloadItem.h"
#import <UIKit/UIKit.h>

/// ZADonwloadManager is built on top of NSURLSession
/// Support many featues:
///     - Download files, images and save to custom directory.
///     - Support download files with priority: HIGH, MEDIUM, LOW
///     - Optimize download on multithread and only download 1 time if there are many same requests.
///     - Support checks how many downloading files.
///     - Support config timeout interval for DownloadManager.
///     - Support download multiple files at the same time.
///     - Support start, pause, resume, retry download.
///     - Support download background or foreground mode.
///     - Support to set maximum concurrent downloads.
///     - Support number of retry time and retry time interval when download failed.
///     - Support to delete file by URL or name and clear all files that have been downloaded. (not yet).
@interface ZADownloadManager : NSObject

+ (ZADownloadManager*)sharedZADownloadManager;

/// Maximum Concurrent downloadTasks
/// Defautl: maxConcurrentDownloads = -1, no limit the concurrent downloadtasks._retryDownloadingOfCommonDownloadItem
@property (nonatomic, assign) NSInteger maxConcurrentDownloads;
@property (nonatomic, assign) NSUInteger timeoutIntervalForRequest;
@property (nonatomic, readonly) NSUInteger numberOfDownloadingUrls;

/// Start download a file with item
/// @param requestItem info of download file.
- (void)downloadFileWithRequestItem:(ZARequestItem *)requestItem;

/// Start download a FILE
/// @param requestItem Info of download file
/// @param retryCount numb of retry when download failed
/// @param retryInterval interval each retry time
- (void)downloadFileWithRequestItem:(ZARequestItem *)requestItem
                         retryCount:(NSUInteger)retryCount
                      retryInterval:(NSUInteger)retryInterval;

/// Start download a file
/// @param urlString url download
/// @param destinationUrl destination to save file
/// @param backgroundMode download background or not
/// @param retryCount retry count
/// @param timeoutInterval timeout
/// @param priority priority
/// @param progressBlock received progress through this block
/// @param completionBlock completion block
/// @param errorBlock error block
- (ZARequestItem *)downloadFileWithURL:(NSString *)urlString
                        destinationUrl:(NSURL *)destinationUrl
                  enableBackgroundMode:(BOOL)backgroundMode
                            retryCount:(NSUInteger)retryCount
                         retryInterval:(NSUInteger)timeoutInterval
                              priority:(ZADownloadModelPriroity)priority
                              progress:(ZADownloadProgressBlock)progressBlock
                            completion:(ZADownloadCompletionBlock)completionBlock
                               failure:(ZADownloadErrorBlock)errorBlock;

- (void)downloadFileWithURL:(NSString *)urlString
              directoryName:(NSString *)directoryName
       enableBackgroundMode:(BOOL)backgroundMode
                   priority:(ZADownloadModelPriroity)priority
                   progress:(ZADownloadProgressBlock)progressBlock
                 completion:(ZADownloadCompletionBlock)completionBlock
                    failure:(ZADownloadErrorBlock)errorBlock;

- (void)downloadFileWithURL:(NSString *)urlString
                   progress:(ZADownloadProgressBlock)progressBlock
                 completion:(ZADownloadCompletionBlock)completionBlock
                    failure:(ZADownloadErrorBlock)errorBlock;

/// Download a Image with a UrlString
/// @param urlString url of image
/// @param completionBlock completion block
/// @param errorBlock error block
- (void)downloadImageWithUrl:(NSString *)urlString
                  completion:(void(^)(UIImage *image, NSURL *destinationUrl))completionBlock
                     failure:(void(^)(NSError* error))errorBlock;

/// PASUSE download of this Item
/// @param requestItem item which will be paused
- (void)pauseDownloadingOfRequest:(ZARequestItem *)requestItem;

/// RESUME download if this item is paused
/// @param requestItem item which will be resumed
- (void)resumeDownloadingOfRequest:(ZARequestItem *)requestItem;

/// RETRY download this item
/// @param requestItem item will be retry download
- (void)retryDownloadingOfRequestItem:(ZARequestItem *)requestItem;

/// CANCEL download this item
/// @param requestItem item will be canceled download
- (void)cancelDownloadingOfRequest:(ZARequestItem *)requestItem;

@end
