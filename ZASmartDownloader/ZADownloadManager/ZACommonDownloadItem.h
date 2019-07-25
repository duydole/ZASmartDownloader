#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import "ZARequestItem.h"

@class ZARequestItem;

// ZACommonDownloadItem manage dictionary of ZARequestItems (has the same UrlString).
@interface ZACommonDownloadItem : NSObject

@property NSMutableDictionary <NSString*,ZARequestItem*> *requestItemsDict;             // dictionary of ZARequestItems, each ZARequestItem ~ 1 request.
@property (nonatomic, readonly) NSUInteger totalDownloadingSubItems;                    // total DownloadRequests which are waiting for the file.
@property (strong, nonatomic) NSURLSessionDownloadTask *commonDownloadTask;             // downloadTask for all DownloadItems has the same Url.
@property (nonatomic) BOOL backgroundMode;                                              // download mode of DownloadTask
@property (nonatomic) ZADownloadItemState commonState;                                  // common state for all DownloadItems has the same Url.
@property (nonatomic) ZADownloadModelPriroity commonPriority;                           // common Priority for all DownloadItems has the same Url.
@property (copy, nonatomic) NSDate *startDate;                                          // start downloading url
@property (copy, nonatomic) NSData *commonResumeData;                                   // common Resume Data for all DownloadItems.
@property (nonatomic) NSUInteger retryCount;                                            // number of retrying download.
@property (nonatomic) NSUInteger retryInterval;                                         // time interval between each Retry.

// init
- (instancetype) initWithRequestItem:(ZARequestItem*)requestItem;

// add a RequestItem to Dictionary:
- (void) addRequestItem:(ZARequestItem*)requestItem;

// remove a Request:
- (void) removeARequestItem:(ZARequestItem*)requestItem;

// execute a RequestItem
- (void) startDownloadingRequest:(NSString*)requestId;
- (void) startDownloadingAllRequests;

// start all Pending RequestItems.
- (void) startAllPendingRequestItems;

// pause a RequestItem
- (void) pauseAlls;
- (void) pauseDownloadingWithRequestId:(NSString*)requestId;

// resume a RequestItem
- (void) resumeDownloadingWithRequestId:(NSString*)requestId urlSession:(NSURLSession*)session;

// cancel a RequestItem.
- (void) cancelDownloadingWithRequestId:(NSString*)requestId;

// reset RetryCount to MaxRetryCount.
- (void) resetRetryCount;

@end
