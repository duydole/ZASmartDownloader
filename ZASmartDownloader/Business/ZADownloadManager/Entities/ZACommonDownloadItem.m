#import "ZACommonDownloadItem.h"

@interface ZACommonDownloadItem()

@property (nonatomic, assign) NSUInteger maxRetryCount;

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

# pragma mark - Control item

- (void)startDownloadingAllRequests {
    for (NSString *identifier in self.requestItemsDict) {
        [self startDownloadingRequest:identifier];
    }
    [_commonDownloadTask resume];
}

- (void)startDownloadingRequest:(NSString *)requestId {
    
    ZARequestItem *requestItem = [_requestItemsDict objectForKey:requestId];
    
    // nếu có trong dict:
    if (requestItem) {
        // nếu chưa có Biz nào tải:
        if (_totalDownloadingSubItems == 0) {
            _commonState = ZADownloadItemStateDownloading;
            [_commonDownloadTask resume];
        }
        
        _totalDownloadingSubItems++;
        requestItem.state = ZADownloadItemStateDownloading;
    }
}

- (void)startAllPendingRequestItems {
    
    _totalDownloadingSubItems = _requestItemsDict.allValues.count;
    
    _commonState = ZADownloadItemStateDownloading;
    
    for (ZARequestItem *downloadItem in _requestItemsDict.allValues) {
        downloadItem.state = ZADownloadItemStateDownloading;
    }
    
    [_commonDownloadTask resume];
}

- (void)pauseAlls {
    for (NSString *identifier in self.requestItemsDict) {
        [self pauseDownloadingWithRequestId:identifier];
    }
}

- (void)pauseDownloadingWithRequestId:(NSString *) identifier {
    // pause logic:
    ZARequestItem *downloadItem = [_requestItemsDict objectForKey:identifier];
    downloadItem.state = ZADownloadItemStatePaused;
    _totalDownloadingSubItems--;
    
    // pause download task:
    if (_totalDownloadingSubItems <= 0) {
        self.commonState = ZADownloadItemStatePaused;
        [_commonDownloadTask cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
            if (resumeData) {
                self.commonResumeData = resumeData;
            }
        }];
    }
}

// resume a Paused DownloadItem with Id and Session (which used to create DownloadTask)
- (void)resumeDownloadingWithRequestId:(NSString *)identifier urlSession:(NSURLSession *)session {
    
    ZARequestItem *requestItem = [_requestItemsDict objectForKey:identifier];
    if (!requestItem) {
        return;
    }
    
    // commonState:
    switch (self.commonState) {
        case ZADownloadItemStateDownloading:
            _totalDownloadingSubItems++;
            requestItem.state = ZADownloadItemStateDownloading;
            break;
        case ZADownloadItemStatePaused:
            
            break;
        case ZADownloadItemStatePending:
            break;
        case ZADownloadItemStateInterrupted:
            break;
        default:
            break;
    }
    
    
    
    // if has a other DownloadItem is Downloading -> turn on StateDownloading.
    if (_commonState == ZADownloadItemStateDownloading) {

    } else {
        
    }
    
    // if all paused:
    if (requestItem && self.commonResumeData && (self.commonState == ZADownloadItemStatePaused || self.commonState == ZADownloadItemStateInterrupted)) {
        // newDownloadTask
        NSURLSessionDownloadTask *downloadTask = [session downloadTaskWithResumeData:self.commonResumeData];
        self.commonDownloadTask = downloadTask;
        _totalDownloadingSubItems ++;
        NSLog(@"dld: Resume success, total downloading: %lu",_totalDownloadingSubItems);
        self.commonState = ZADownloadItemStateDownloading;
        requestItem.state = ZADownloadItemStateDownloading;
        [downloadTask resume];
        return;
    }
    
    // if all paused/interrupted.. but don't have resume Data
    if (!self.commonResumeData) {
        // cancel:
        [_commonDownloadTask cancel];
        
        _commonState = ZADownloadItemStateDownloading;
        requestItem.state = ZADownloadItemStateDownloading;
        
        // create download task
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:requestItem.urlString]];
        NSURLSessionDownloadTask *downloadTask = [session downloadTaskWithRequest:request];
        [downloadTask resume];
    }
}

- (void)cancelDownloadingWithRequestId:(NSString *)identifier {

    ZARequestItem *downloadItem = [_requestItemsDict objectForKey:identifier];
    
    if (downloadItem.state == ZADownloadItemStateDownloading) {
        _totalDownloadingSubItems--;
    }
    
    [self.requestItemsDict removeObjectForKey:identifier];
    
    // don't have any requests -> cancel CommonDownloadTask.
    if (_requestItemsDict.count == 0) {
        [self.commonDownloadTask cancel];
    }
}

- (void)addRequestItem:(ZARequestItem *)requestItem {
    if (requestItem.state == ZADownloadItemStateDownloading) {
        _totalDownloadingSubItems++;
    }
    [_requestItemsDict setObject:requestItem forKey:requestItem.requestId];
}

- (void)removeARequestItem:(ZARequestItem *)requestItem {
    // if remove a Downloading Request Item and it is existed in Dict.
    if ((requestItem.state == ZADownloadItemStateDownloading) && [_requestItemsDict objectForKey:requestItem.requestId]) {
        _totalDownloadingSubItems--;
    }
    
    [_requestItemsDict removeObjectForKey:requestItem.requestId];
}

# pragma mark - Private methods

- (void)setRetryCount:(NSUInteger)retryCount {
    _retryCount = retryCount;
    if (_maxRetryCount == 0) {
        _maxRetryCount = retryCount;
    }
}

- (void)resetRetryCount {
    _retryCount = _maxRetryCount;
}

@end
