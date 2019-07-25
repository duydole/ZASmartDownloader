#import "ZACommonDownloadItem.h"

@interface ZACommonDownloadItem()

@property NSUInteger maxRetryCount;

@end

@implementation ZACommonDownloadItem

- (instancetype) initWithRequestItem:(ZARequestItem *)requestItem {
    self = [super init];
    if (self) {
        _requestItemsDict = [[NSMutableDictionary alloc] initWithObjects:@[requestItem] forKeys:@[requestItem.requestId]];
        _backgroundMode = requestItem.backgroundMode;
        _commonPriority = requestItem.priority;
    }
    return self;
}

# pragma mark - private methods:
- (void) setRetryCount:(NSUInteger)retryCount {
    _retryCount = retryCount;
    if (_maxRetryCount == 0) {
        _maxRetryCount = retryCount;
    }
}

- (void) resetRetryCount {
    _retryCount = _maxRetryCount;
}

# pragma mark - control item
- (void) startDownloadingRequest:(NSString *)requestId {
    
    ZARequestItem *requestItem = [_requestItemsDict objectForKey:requestId];
    
    if (requestItem) {
        _totalDownloadingSubItems++;
        _commonState = ZADownloadItemStateDownloading;
        requestItem.state = ZADownloadItemStateDownloading;
        [_commonDownloadTask resume];
    }
}

- (void) startAllPendingDownloadItems {
    
    _totalDownloadingSubItems = _requestItemsDict.allValues.count;
    
    _commonState = ZADownloadItemStateDownloading;
    
    for (ZARequestItem *downloadItem in _requestItemsDict.allValues) {
        downloadItem.state = ZADownloadItemStateDownloading;
    }
    
    [_commonDownloadTask resume];
}

- (void) pauseDownloadingWithRequestId:(NSString *) identifier {
    
    // pause logic:
    
    ZARequestItem *downloadItem = [_requestItemsDict objectForKey:identifier];
    
    downloadItem.state = ZADownloadItemStatePaused;
    
    _totalDownloadingSubItems--;
    
    // pause download task:
    if (_totalDownloadingSubItems <= 0) {
        
        [_commonDownloadTask cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
         
            self.commonState = ZADownloadItemStatePaused;
            
            self.commonResumeData = resumeData;
       
        }];
    }
}

// resume a DownloadItem with Id and Session (which used to create DownloadTask)
- (void) resumeDownloadingWithRequestId:(NSString *)identifier urlSession:(NSURLSession *)session {
    
    ZARequestItem *downloadItem = [_requestItemsDict objectForKey:identifier];
    
    // if has a other DownloadItem is Downloading.
    
    if (_totalDownloadingSubItems > 0) {
        
        _totalDownloadingSubItems++;
        
        downloadItem.state = ZADownloadItemStateDownloading;
        
        NSLog(@"dld: Resume success, total downloading: %lu",_totalDownloadingSubItems);
        
        return;
    }
    
    // if all paused:
    if (downloadItem && self.commonResumeData && (self.commonState == ZADownloadItemStatePaused || self.commonState == ZADownloadItemStateInterrupted)) {
    
        // newDownloadTask
        NSURLSessionDownloadTask *downloadTask = [session downloadTaskWithResumeData:self.commonResumeData];
        
        self.commonDownloadTask = downloadTask;
        
        _totalDownloadingSubItems ++;
        
        NSLog(@"dld: Resume success, total downloading: %lu",_totalDownloadingSubItems);
        
        self.commonState = ZADownloadItemStateDownloading;
        
        downloadItem.state = ZADownloadItemStateDownloading;
        
        [downloadTask resume];
    }
}

- (void) cancelDownloadingWithRequestId:(NSString *)identifier {

    ZARequestItem *downloadItem = [_requestItemsDict objectForKey:identifier];
    
    if (downloadItem.state == ZADownloadItemStateDownloading) {
        _totalDownloadingSubItems--;
    }
    
    [self.requestItemsDict removeObjectForKey:identifier];
    
    // khi không còn thằng nào muốn tải nữa.
    if (_requestItemsDict.count == 0) {
        
        [self.commonDownloadTask cancel];
    
    }
    
}

- (void) addRequestItem:(ZARequestItem *)requestItem {
    if (requestItem.state == ZADownloadItemStateDownloading) {
        _totalDownloadingSubItems++;
    }
    [_requestItemsDict setObject:requestItem forKey:requestItem.requestId];
}

@end
