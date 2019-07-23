#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

// Defined blocks:
typedef void(^ZADownloadProgressBlock)(CGFloat progress, NSUInteger speed, NSUInteger remainingSeconds);                // Progress block.
typedef void(^ZADownloadCompletionBlock)(NSURL *destinationUrl);                                                        // Completion block.
typedef void(^ZADownloadErrorBlock)(NSError *error);                                                                    // Error block.

// Defined DownloadModel State.
typedef NS_ENUM(NSInteger, ZADownloadModelState) {
    ZADownloadModelStateDowloading,                         // downloading
    ZADownloadModelStatePaused,                             // paused.
    ZADownloadModelStateWaiting,                            // waiting to download, not yet downloaded any bytes.
    ZADownloadModelStateCancelled,                          // user cancel
    //ZADownloadModelStateCompleted,                        // download completed.
    ZADownloadModelStateInterrupted
};

// Defined ErrorCode when downloading.
typedef NS_ENUM(NSInteger, DownloadErrorCode) {
    DownloadErrorCodeLossConnection,
    DownloadErrorCodeNoConnection,
    DownloadErrorCodeTimeoutRequest,
    DownloadErrorCodeInvalidUrl,
    DownloadErrorCodeCannotBeResumed
};

// Defined Download Priority.
typedef NS_ENUM(NSInteger, ZADownloadModelPriroity) {
    ZADownloadModelPriroityHigh,                        // High
    ZADownloadModelPriroityMedium,                      // Medium
    ZADownloadModelPriroityLow                          // Low
};

// defined SubDownloadItem
@interface ZASubDownloadItem : NSObject

@property ZADownloadCompletionBlock completionBlock;
@property ZADownloadModelState subState;
@property NSURL *destinationUrl;

@end

// ZADownloadModel
@interface ZADownloadItem : NSObject

@property (copy, nonatomic) ZADownloadProgressBlock progressBlock;

// test call back for all business progression block:
@property NSMutableArray<ZADownloadProgressBlock> *listProgressBlock;

@property NSMutableArray<ZADownloadCompletionBlock> *listCompletionBlock;

// test 1:
@property NSMutableDictionary *completionBlockDict;

// test 2:
@property NSMutableArray <ZASubDownloadItem*> *listSubDownloadItems;

@property NSMutableArray<ZADownloadErrorBlock> *listErrorBlock;
@property (strong, nonatomic) NSURLSessionDownloadTask *downloadTask;
@property (nonatomic) ZADownloadModelState state;
@property (nonatomic) ZADownloadModelPriroity priority;
@property (nonatomic) BOOL isBackgroundMode;
@property (nonatomic) NSURL *destinationUrl;
@property (copy, nonatomic) NSString *fileName;
@property (copy, nonatomic) NSString *directoryName;
@property (copy, nonatomic) NSDate *startDate;
@property (copy, nonatomic) NSData *resumeData;
@property (nonatomic) NSUInteger retryCount;
@property (nonatomic) NSUInteger retryInterval;

/**
 Initialize a DownloadModel with:

 @param downloadTask : download task
 @param progressBlock : is called to manage the download progress.
 @param completionBlock : is called when the download successed.
 @param errorBlock : is called when occurring error.
 @param isBackgroundMode : YES if allow to download in background, and vice versa.
 @param priority : the Priority of Download File.
 @return DownloadModel instance.
 */
- (instancetype) initWithDownloadTask:(NSURLSessionDownloadTask*)downloadTask
                       destinationUrl:(NSURL*)destinationUrl
                             progress:(ZADownloadProgressBlock)progressBlock
                           completion:(ZADownloadCompletionBlock)completionBlock
                              failure:(ZADownloadErrorBlock)errorBlock
                     isBackgroundMode:(BOOL)isBackgroundMode
                             priority:(ZADownloadModelPriroity)priority;

// add CompletionBlock to DownloadModel, which want to call when download success.
- (void) addCompletionBlock: (ZADownloadCompletionBlock)completionBlock;

// TEST: add ZADownloadProgressBlock to DownloadModel, which want to call when download success.
- (void) addProgressBlock: (ZADownloadProgressBlock)progressBlock;

- (void) addCompletionBlock:(ZADownloadCompletionBlock)completionBlock withDestinationUrl:(NSURL*)destinationUrl;

// add ErrorBlock to DownloadModel, which want to call when occurring error.
- (void) addErrorBlock: (ZADownloadErrorBlock)errorBlock;

// forward to all CompletionBlocks.
- (void) forwardAllCompletionBlockWithDestinationUrl:(NSURL*)destinationUrl;

// forward to all ErrorBlocks.
- (void) forwardAllErrorBlockWithError: (NSError*)error;

// reset RetryCount to MaxRetryCount.
- (void) resetRetryCount;

// execute
- (void) start;

// pause.
- (void) pause;

// cancel:
- (void) cancel;

// get total waiting request:
- (NSUInteger) totalWaitingRequest;

@end
