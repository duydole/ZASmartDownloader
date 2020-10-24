#import "ZACommonDownloadItem.h"
#import "LDCommonMacros.h"

@interface ZACommonDownloadItem()

@property (nonatomic, assign) NSUInteger maxRetryCount;

@end

@implementation ZACommonDownloadItem

- (instancetype)initWithRequestItem:(ZARequestItem *)requestItem {
    self = [super init];
    if (self) {
        _requestItemsDict =[NSMutableDictionary new];
        _requestItemsDict[requestItem.requestId] = requestItem;
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

- (void)resumeDownloadingWithRequestId:(NSString *)identifier urlSession:(NSURLSession *)session {
    
    /// CommonItem sẽ resume 1 subitem mà nó quản lý bằng URLSession input.
    ZARequestItem *subItem = [_requestItemsDict objectForKey:identifier];
    ifnot (subItem) {
        NSAssert(NO, @"Common item is not contain subitem with id %@",identifier);
        return;
    }
    
    /// Tùy vào state của commonItem mà sẽ quyết định resume khác nhau
    switch (self.commonState) {
        case ZADownloadItemStateDownloading:
        {
            /// Nếu commonItem đang downloading thì mark subItem as Downloading.
            _totalDownloadingSubItems++;
            subItem.state = ZADownloadItemStateDownloading;
            break;
        }
        case ZADownloadItemStatePaused:
        case ZADownloadItemStateInterrupted:
        {
            /// Nếu commonItem đang paused, interrupted
            /// Mà subItem đòi download
            if (self.commonResumeData) {
                
                ///Nếu có resumeData thì update data + download thôi
                _totalDownloadingSubItems++;
                self.commonState = ZADownloadItemStateDownloading;
                subItem.state = ZADownloadItemStateDownloading;
                
                ///Start download with resumeData
                NSURLSessionDownloadTask *downloadTask = [session downloadTaskWithResumeData:self.commonResumeData];
                self.commonDownloadTask = downloadTask;
                [downloadTask resume];
            } else {
                ///Nếu không có resumeData thì download thường thôi:
                [_commonDownloadTask cancel];
                _commonState = ZADownloadItemStateDownloading;
                subItem.state = ZADownloadItemStateDownloading;
                
                ///Start download without resumeData
                NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:subItem.urlString]];
                NSURLSessionDownloadTask *downloadTask = [session downloadTaskWithRequest:request];
                self.commonDownloadTask = downloadTask;
                [downloadTask resume];
            }
            break;
        }
        case ZADownloadItemStatePending:
            break;
        default:
            break;
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
