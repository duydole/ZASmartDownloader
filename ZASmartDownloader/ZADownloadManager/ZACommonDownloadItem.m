#import "ZACommonDownloadItem.h"

@interface ZACommonDownloadItem()

@property NSUInteger maxRetryCount;

@end

@implementation ZACommonDownloadItem

- (instancetype) initWithRequestItem:(ZADownloadItem *)requestItem {
    
    self = [super init];
    
    if (self) {
    
        _downloadItemsDict = [[NSMutableDictionary alloc] initWithObjects:@[requestItem] forKeys:@[requestItem.requestId]];
        
        _backgroundMode = requestItem.isBackgroundMode;
        
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
    
    _totalDownloadingSubItems++;
    
    _commonState = ZADownloadModelStateDowloading;
    
    ZADownloadItem *requestItem = [_downloadItemsDict objectForKey:requestId];
    
    requestItem.state = ZADownloadModelStateDowloading;
    
    [_downloadTask resume];
}

- (void) startAllPendingDownloadItems {
    
    _totalDownloadingSubItems = _downloadItemsDict.allValues.count;
    
    _commonState = ZADownloadModelStateDowloading;
    
    for (ZADownloadItem *downloadItem in _downloadItemsDict.allValues) {
        downloadItem.state = ZADownloadModelStateDowloading;
    }
    
    [_downloadTask resume];
}

- (void) pauseWithId:(NSString *) identifier {
    
    // pause logic:
    
    ZADownloadItem *downloadItem = [_downloadItemsDict objectForKey:identifier];
    
    downloadItem.state = ZADownloadModelStatePaused;
    
    _totalDownloadingSubItems--;
    
    // pause download task:
    if (_totalDownloadingSubItems <= 0) {
        
        [_downloadTask cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
         
            self.commonState = ZADownloadModelStatePaused;
            
            self.commonResumeData = resumeData;
       
        }];
    }
}

// resume a DownloadItem with Id and Session (which used to create DownloadTask)
- (void) resumeWithId:(NSString *)identifier urlSession:(NSURLSession *)session {
    
    ZADownloadItem *downloadItem = [_downloadItemsDict objectForKey:identifier];
    
    // if has a other DownloadItem is Downloading.
    
    if (_totalDownloadingSubItems > 0) {
        
        _totalDownloadingSubItems++;
        
        downloadItem.state = ZADownloadModelStateDowloading;
        
        NSLog(@"dld: Resume success, total downloading: %lu",_totalDownloadingSubItems);
        
        return;
    }
    
    
    // if all paused:
    if (downloadItem && self.commonResumeData && (self.commonState == ZADownloadModelStatePaused || self.commonState == ZADownloadModelStateInterrupted)) {
    
        // newDownloadTask
        NSURLSessionDownloadTask *downloadTask = [session downloadTaskWithResumeData:self.commonResumeData];
        
        self.downloadTask = downloadTask;
        
        _totalDownloadingSubItems ++;
        
        NSLog(@"dld: Resume success, total downloading: %lu",_totalDownloadingSubItems);
        
        self.commonState = ZADownloadModelStateDowloading;
        
        downloadItem.state = ZADownloadModelStateDowloading;
        
        [downloadTask resume];
    }
}

- (void) cancelWithId:(NSString *)identifier {

    ZADownloadItem *downloadItem = [_downloadItemsDict objectForKey:identifier];
    
    if (downloadItem.state == ZADownloadModelStateDowloading) {
        _totalDownloadingSubItems--;
    }
    
    [self.downloadItemsDict removeObjectForKey:identifier];
    
    // khi không còn thằng nào muốn tải nữa.
    if (_downloadItemsDict.count == 0) {
        
        [self.downloadTask cancel];
    
    }
    
}

- (NSUInteger) totalWaitingRequest {
//    return _listCompletionBlock.count;
    return 1;
}

- (void) addDownloadItem:(ZADownloadItem *)downloadItem {
    
    [_downloadItemsDict setObject:downloadItem forKey:downloadItem.requestId];

}

@end


// impletion ZASubDownloadItem
@implementation ZADownloadItem

- (instancetype)initWithUrlString:(NSString *)urlString
                 isBackgroundMode:(BOOL)isBackgroundMode
                         priority:(ZADownloadModelPriroity)priority
                   destinationUrl:(NSURL *)destinationUrl
                         progress:(ZADownloadProgressBlock)progressBlock
                       completion:(ZADownloadCompletionBlock)completionBlock
                          failure:(ZADownloadErrorBlock)errorBlock {
    
    self = [super init];
    
    if (self) {
        _requestId = [[NSUUID UUID] UUIDString];
        _urlString = urlString;
        _isBackgroundMode = isBackgroundMode;
        _priority = priority;
        _destinationUrl = destinationUrl;
        _progressBlock = progressBlock;
        _completionBlock = completionBlock;
        _errorBlock = errorBlock;
        _state = ZADownloadModelStateDowloading;        // ?????
    }
    
    return self;
}


@end
