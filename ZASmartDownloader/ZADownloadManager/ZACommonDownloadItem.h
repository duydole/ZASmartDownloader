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
    ZADownloadModelStatePending,                            // waiting to download, not yet downloaded any bytes.
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

// defined ZADownloadRequest
@interface ZADownloadItem : NSObject

@property NSString *requestId;                              // id of request
@property NSString *urlString;                              // urlString
@property BOOL isBackgroundMode;                            // background or foreground download.
@property ZADownloadModelPriroity priority;                 // priority
@property ZADownloadProgressBlock progressBlock;            // progress block
@property ZADownloadCompletionBlock completionBlock;        // completion block.
@property ZADownloadErrorBlock errorBlock;                  // error block
@property ZADownloadModelState state;                       // state of request
@property NSURL *destinationUrl;                            // destination of request.

- (instancetype) initWithUrlString:(NSString*)urlString
                  isBackgroundMode:(BOOL)isBackgroundMode
                          priority:(ZADownloadModelPriroity)priority
                    destinationUrl:(NSURL*)destinationUrl
                          progress:(ZADownloadProgressBlock)progressBlock
                        completion:(ZADownloadCompletionBlock)completionBlock
                           failure:(ZADownloadErrorBlock)errorBlock;
@end

// ZADownloadModel
@interface ZACommonDownloadItem : NSObject

@property NSMutableDictionary <NSString*,ZADownloadItem*> *downloadItemsDict;           // dictionary of DownloadItems, each DownloadItem ~ 1 request.
@property (strong, nonatomic) NSURLSessionDownloadTask *downloadTask;                   // downloadTask for all DownloadItems has the same Url.
@property (nonatomic) BOOL backgroundMode;                                              // download mode of DownloadTask
@property (nonatomic) ZADownloadModelState commonState;                                 // common state for all DownloadItems has the same Url.
@property (nonatomic) ZADownloadModelPriroity commonPriority;                           // common Priority for all DownloadItems has the same Url.
@property (copy, nonatomic) NSDate *startDate;                                          // start downloading url
@property (copy, nonatomic) NSData *commonResumeData;                                   // common Resume Data for all DownloadItems.
@property (nonatomic) NSUInteger retryCount;
@property (nonatomic) NSUInteger retryInterval;

@property (nonatomic) NSUInteger totalDownloadingSubItems;                              // total DownloadRequests which are waiting for the file.

- (instancetype) initWithRequestItem:(ZADownloadItem*)requestItem;

- (void) addDownloadItem:(ZADownloadItem*)downloadItem;

// reset RetryCount to MaxRetryCount.
- (void) resetRetryCount;

// execute
- (void) startDownloadingRequest:(NSString*)requestId;

- (void) startAllPendingDownloadItems;

// pause.
- (void) pauseWithId:(NSString*)identifier;

// resume
- (void) resumeWithId:(NSString*)identifier urlSession:(NSURLSession*)session;

// cancel:
- (void) cancelWithId:(NSString*)identifier;

// get total waiting request:
- (NSUInteger) totalWaitingRequest;

@end
