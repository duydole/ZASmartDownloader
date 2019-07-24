#import "ZADownloadItem.h"

@interface ZADownloadItem()

@property NSUInteger maxRetryCount;

@end

@implementation ZADownloadItem

- (instancetype)initWithDownloadTask:(NSURLSessionDownloadTask *)downloadTask
                      destinationUrl:(NSURL*)destinationUrl
                            progress:(ZADownloadProgressBlock)progressBlock
                          completion:(ZADownloadCompletionBlock)completionBlock
                             failure:(ZADownloadErrorBlock)errorBlock
                    isBackgroundMode:(BOOL)isBackgroundMode
                            priority:(ZADownloadModelPriroity)priority {
    self = [super init];
    if (self) {
        _downloadTask = downloadTask;
        _listDownloadRequests = [[NSMutableArray alloc] init];

        // ver 1:
        _listCompletionBlock = [[NSMutableArray alloc] initWithObjects:completionBlock, nil];

        
        _listErrorBlock = [[NSMutableArray alloc] initWithObjects:errorBlock, nil];
        _state = ZADownloadModelStatePending;
        _isBackgroundMode = isBackgroundMode;
        _priority = priority;
        _destinationUrl = [[NSURL alloc] init];
    }
    return self;
}

- (instancetype) init {
    self = [super init];
    if (self) {
        _resumeData = [[NSData alloc] init];
        _downloadTask = [[NSURLSessionDownloadTask alloc] init];
        _listCompletionBlock = [[NSMutableArray alloc] init];
        _retryCount = 0;
        _retryInterval = 0;
        _maxRetryCount = 0;
    }
    return self;
}

- (void) addCompletionBlock: (ZADownloadCompletionBlock)completionBlock {
    [_listCompletionBlock addObject:completionBlock];
}

- (void) forwardAllCompletionBlockWithDestinationUrl:(NSURL*)destinationUrl {
    // foward:
    for (int i=0; i<_listCompletionBlock.count; i++) {
        ZADownloadCompletionBlock completionBlock = _listCompletionBlock[i];
        dispatch_async(dispatch_get_main_queue(), ^{
            completionBlock(destinationUrl);
        });
    }
    
    // reset:
    [_listCompletionBlock removeAllObjects];
}

- (void) addErrorBlock: (ZADownloadErrorBlock)errorBlock {
    [_listErrorBlock addObject:errorBlock];
}

- (void) forwardAllErrorBlockWithError:(NSError *)error {
    if (error && self.listErrorBlock) {
        for (int i=0; i<_listErrorBlock.count; i++) {
            ZADownloadErrorBlock errorBlock = _listErrorBlock[i];
            dispatch_async(dispatch_get_main_queue(), ^{
                errorBlock(error);
            });
        }
    }
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
- (void) start {
    _state = ZADownloadModelStateDowloading;
    [_downloadTask resume];
}

- (void) startDownloadSubItem:(NSString *)identifier {
    NSLog(@"dld: begin to start subItem: %@",identifier);
    NSLog(@"dld: total sub item: %lu",_listDownloadRequests.count);
    
    _state = ZADownloadModelStateDowloading;

    for (ZADownloadRequest *subItem in self.listDownloadRequests) {
        if ([subItem.identifer isEqualToString:identifier]) {
            subItem.state = ZADownloadModelStateDowloading;
            [_downloadTask resume];
            NSLog(@"dld: finished to start subItem: %@",identifier);
        }
    }
}


- (void) pause {
    // nếu có ít nhất 1 thằng đang downloading -> thì ko change trạng thái.
    
    if (_state == ZADownloadModelStateDowloading) {
        _state = ZADownloadModelStatePaused;
        [_downloadTask cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
            if (resumeData) {
                // pause success:
                self.resumeData = resumeData;
            } else {
                // Download can't be resumed.
                NSError *error = [[NSError alloc] initWithDomain:@"duydl.DownloadManagerDomain" code:DownloadErrorCodeCannotBeResumed userInfo:nil];
                [self forwardAllErrorBlockWithError:error];
                
                // remove?
                
                // self.state = ZADownloadModelStateCancelled;
            }
        }];
    }
}

- (void)pauseWithId:(NSString *)identifier completion:(dispatch_block_t)completion {
    // change state of subItem
    for (ZADownloadRequest *subItem in _listDownloadRequests) {
        if (subItem.identifer == identifier) {
            subItem.state = ZADownloadModelStatePaused;
            
            [_downloadTask cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
                if (resumeData) {
                    self.resumeData = resumeData;
                    completion();
                }
            }];
        }
    }
}

- (void) cancel {
    [_downloadTask cancel];
    //_state = ZADownloadModelStateCancelled;
}

- (NSUInteger)totalWaitingRequest {
    return _listCompletionBlock.count;
}

- (void)addRequest:(ZADownloadRequest *)downloadRequest {
    [_listDownloadRequests addObject:downloadRequest];
}

@end

// impletion ZASubDownloadItem
@implementation ZADownloadRequest

- (instancetype)initWithId:(NSString *)identifier
                completion:(ZADownloadCompletionBlock)completionBlock
                  progress:(ZADownloadProgressBlock)progressBlock
            destinationUrl:(NSURL *)destinationUrl
                     state:(ZADownloadModelState)state {
    self = [super init];
    if (self) {
        _identifer = identifier;
        _completionBlock = completionBlock;
        _progressBlock = progressBlock;
        _destinationUrl = destinationUrl;
        _state = state;
    }
    return self;
}

@end
