//
//  ZARequestItem.h
//  ZASmartDownloader
//
//  Created by Duy on 7/24/19.
//  Copyright © 2019 vng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

// Defined blocks:
typedef void(^ZADownloadProgressBlock)(CGFloat progress, NSUInteger speed, NSUInteger remainingSeconds);                // Progress block.
typedef void(^ZADownloadCompletionBlock)(NSURL *destinationUrl);                                                        // Completion block.
typedef void(^ZADownloadErrorBlock)(NSError *error);                                                                    // Error block.

// Defined DownloadItem State.
typedef NS_ENUM(NSInteger, ZADownloadItemState) {
    ZADownloadItemStateDownloading,                         // downloading
    ZADownloadItemStatePaused,                              // paused.
    ZADownloadItemStatePending,                             // waiting to download, not yet downloaded any bytes.
    ZADownloadItemStateInterrupted                          // interrupted
};

// Defined ErrorCode when downloading.
typedef NS_ENUM(NSInteger, DownloadErrorCode) {
    DownloadErrorCodeLossConnection,
    DownloadErrorCodeNoConnection,
    DownloadErrorCodeTimeoutRequest,
    DownloadErrorCodeInvalidUrl,
    DownloadErrorCodeCannotBeResumed,
    DownloadErrorCodeOverMaxConcurrentDownloads
};

// Defined Download Priority.
typedef NS_ENUM(NSInteger, ZADownloadModelPriroity) {
    ZADownloadModelPriroityLow,                         // Low
    ZADownloadModelPriroityMedium,                      // Medium
    ZADownloadModelPriroityHigh,                        // High
};

// defined ZADownloadRequest
@interface ZARequestItem : NSObject

@property NSString *requestId;                              // id of request
@property NSString *urlString;                              // urlString
@property BOOL backgroundMode;                              // background or foreground download.
@property NSURL *destinationUrl;                            // destination of request.
@property ZADownloadItemState state;                        // state of request
@property ZADownloadModelPriroity priority;                 // priority
@property ZADownloadProgressBlock progressBlock;            // progress block
@property ZADownloadCompletionBlock completionBlock;        // completion block.
@property ZADownloadErrorBlock errorBlock;                  // error block

- (instancetype) initWithUrlString:(NSString*)urlString
                  isBackgroundMode:(BOOL)isBackgroundMode
                    destinationUrl:(NSURL*)destinationUrl
                          priority:(ZADownloadModelPriroity)priority
                          progress:(ZADownloadProgressBlock)progressBlock
                        completion:(ZADownloadCompletionBlock)completionBlock
                           failure:(ZADownloadErrorBlock)errorBlock;
@end
