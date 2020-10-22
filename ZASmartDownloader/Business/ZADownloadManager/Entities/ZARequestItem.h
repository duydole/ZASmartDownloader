//
//  ZARequestItem.h
//  ZASmartDownloader
//
//  Created by Duy on 7/24/19.
//  Copyright © 2019 vng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

typedef void(^ZADownloadProgressBlock)(CGFloat progress, NSUInteger speed, NSUInteger remainingSeconds);
typedef void(^ZADownloadCompletionBlock)(NSURL *destinationUrl);
typedef void(^ZADownloadErrorBlock)(NSError *error);

typedef NS_ENUM(NSInteger, ZADownloadItemState) {
    ZADownloadItemStateDownloading,
    ZADownloadItemStatePaused,
    ZADownloadItemStatePending,
    ZADownloadItemStateInterrupted
};

typedef NS_ENUM(NSInteger, DownloadErrorCode) {
    DownloadErrorCodeLossConnection,
    DownloadErrorCodeNoConnection,
    DownloadErrorCodeTimeoutRequest,
    DownloadErrorCodeInvalidUrl,
    DownloadErrorCodeCannotBeResumed,
    DownloadErrorCodeOverMaxConcurrentDownloads
};

typedef NS_ENUM(NSInteger, ZADownloadModelPriroity) {
    ZADownloadModelPriroityLow,
    ZADownloadModelPriroityMedium,
    ZADownloadModelPriroityHigh,
};

@interface ZARequestItem : NSObject

@property (nonatomic, strong) NSString *requestId;
@property (nonatomic, strong) NSString *urlString;
@property (nonatomic, assign) BOOL backgroundMode;
@property (nonatomic, strong) NSURL *destinationUrl;
@property (nonatomic, assign) ZADownloadItemState state;
@property (nonatomic, assign) ZADownloadModelPriroity priority;
@property (nonatomic, strong) ZADownloadProgressBlock progressBlock;
@property (nonatomic, strong) ZADownloadCompletionBlock completionBlock;
@property (nonatomic, strong) ZADownloadErrorBlock errorBlock;
@property (nonatomic, readonly) NSString *fileName;

- (instancetype)initWithUrlString:(NSString*)urlString
                  isBackgroundMode:(BOOL)isBackgroundMode
                    destinationUrl:(NSURL*)destinationUrl
                          priority:(ZADownloadModelPriroity)priority
                          progress:(ZADownloadProgressBlock)progressBlock
                        completion:(ZADownloadCompletionBlock)completionBlock
                           failure:(ZADownloadErrorBlock)errorBlock;

- (BOOL)isExistedOnTempDirectory;

@end
