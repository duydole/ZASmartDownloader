#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import "ZARequestItem.h"

@class ZARequestItem;

// ZACommonDownloadItem manage dictionary of ZARequestItems (has the same UrlString).
@interface ZACommonDownloadItem : NSObject

@property NSMutableDictionary <NSString*,ZARequestItem*> *requestItemsDict;
@property (nonatomic, readonly) NSUInteger totalDownloadingSubItems;
@property (strong, nonatomic) NSURLSessionDownloadTask *commonDownloadTask;
@property (nonatomic) BOOL backgroundMode;
@property (nonatomic) ZADownloadItemState commonState;
@property (nonatomic) ZADownloadModelPriroity commonPriority;
@property (copy, nonatomic) NSDate *startDate;
@property (copy, nonatomic) NSData *commonResumeData;
@property (nonatomic) NSUInteger retryCount;
@property (nonatomic) NSUInteger retryInterval;

- (instancetype) initWithRequestItem:(ZARequestItem*)requestItem;

- (void) addRequestItem:(ZARequestItem*)requestItem;

- (void) removeARequestItem:(ZARequestItem*)requestItem;

- (void) startDownloadingRequest:(NSString*)requestId;
- (void) startDownloadingAllRequests;

- (void) startAllPendingRequestItems;

- (void) pauseAlls;
- (void) pauseDownloadingWithRequestId:(NSString*)requestId;

- (void) resumeDownloadingWithRequestId:(NSString*)requestId urlSession:(NSURLSession*)session;

- (void) cancelDownloadingWithRequestId:(NSString*)requestId;

- (void) resetRetryCount;

@end
