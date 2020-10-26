//
//  ZASmartDownloader.m
//  ZASmartDownloader
//
//  Created by Do Le Duy on 10/21/20.
//  Copyright © 2020 vng. All rights reserved.
//

#import "ZADownloadManager.h"
#import "AppDelegate.h"
#import "ZAImageCache.h"
#import "Reachability.h"
#import "LDCommonMacros.h"
#import "NSFileManager+Extension.h"
#import "NSURL+Extension.h"

#define IMAGE_DIRECTORY_NAME                @"Downloaded Images"
#define TIMEOUT_INTERVAL_FOR_REQUEST        10
#define NO_LIMIT_CONCURRENT_DOWNLOADS       -1
#define DEFAULT_RETRY_COUNT                 3
#define DEFAULT_RETRY_INTERVAL              10

@interface ZADownloadManager() <NSURLSessionDelegate, NSURLSessionDownloadDelegate>

@property (nonatomic, strong) Reachability *internetReachability;
@property (nonatomic, assign) NSUInteger totalDownloadingUrls;

@property (nonatomic, strong) NSURLSession *forcegroundURLSession;
@property (nonatomic, strong) NSURLSession *backgroundURLSession;

@property (nonatomic, strong) dispatch_queue_t serialQueue;
@property (nonatomic, strong) dispatch_queue_t concurrentQueue;

@property (nonatomic, strong) NSMutableDictionary *backgroundDownloadItemsDict;
@property (nonatomic, strong) NSMutableDictionary *foregroundDownloadItemsDict;

@property (nonatomic, strong) NSMutableArray<ZACommonDownloadItem *> *highPriorityDownloadItems;
@property (nonatomic, strong) NSMutableArray<ZACommonDownloadItem *> *mediumPriorityDownloadItems;
@property (nonatomic, strong) NSMutableArray<ZACommonDownloadItem *> *lowPriorityDownloadItems;

@end

@implementation ZADownloadManager

SYNTHESIZE_SINGLETON_FOR_CLASS(ZADownloadManager);

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    _maxConcurrentDownloads = NO_LIMIT_CONCURRENT_DOWNLOADS;
    _totalDownloadingUrls = 0;
    
    /// Reachability:
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
    self.internetReachability = [Reachability reachabilityForLocalWiFi];
    [self.internetReachability startNotifier];
    
    /// Queues:
    _serialQueue = dispatch_queue_create("duydl.DownloadManager.SerialQueue", DISPATCH_QUEUE_SERIAL);
    _concurrentQueue = dispatch_queue_create("duydl.DownloadManager.ConcurrentQueue", DISPATCH_QUEUE_CONCURRENT);
    
    /// Priority lists:
    _highPriorityDownloadItems = [NSMutableArray new];
    _mediumPriorityDownloadItems = [NSMutableArray new];
    _lowPriorityDownloadItems = [NSMutableArray new];
    
    /// downloadItems dictionary:
    _backgroundDownloadItemsDict = [NSMutableDictionary new];
    _foregroundDownloadItemsDict = [NSMutableDictionary new];
}

#pragma mark - Public methods

- (ZARequestItem *)downloadFileWithURL:(NSString *)urlString
                        destinationUrl:(NSURL *)destinationUrl
                  enableBackgroundMode:(BOOL)backgroundMode
                            retryCount:(NSUInteger)retryCount
                         retryInterval:(NSUInteger)retryInterval
                              priority:(ZADownloadModelPriroity)priority
                              progress:(ZADownloadProgressBlock)progressBlock
                            completion:(ZADownloadCompletionBlock)completionBlock
                               failure:(ZADownloadErrorBlock)errorBlock {
    NSAssert(retryCount >= 0 && retryInterval >= 0, @"");
    
    /// Check URLString
    ifnot ([self _isValidUrlString:urlString]) {
        if (errorBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSError *error = [[NSError alloc] initWithDomain:@"duydl.DownloadManagerDomain" code:DownloadErrorCodeInvalidUrl userInfo:nil];
                errorBlock(error);
            });
        }
        return nil;
    }
    
    /// Check DestinationUrl
    ifnot (destinationUrl) {
        destinationUrl = [DOCUMENT_URL URLByAppendingPathComponent:[urlString lastPathComponent]];
    }
    
    /// Create RequestItem (subModel):
    ZARequestItem *requestItem = [[ZARequestItem alloc]
                                  initWithUrlString:urlString
                                  isBackgroundMode:backgroundMode
                                  destinationUrl:destinationUrl
                                  priority:priority
                                  progress:progressBlock
                                  completion:completionBlock
                                  failure:errorBlock];
    
    /// Start to Download:
    [self downloadFileWithRequestItem:requestItem retryCount:retryCount retryInterval:retryInterval];
    
    return requestItem;
}

- (void)downloadFileWithURL:(NSString *)urlString
              directoryName:(NSString *)directoryName
       enableBackgroundMode:(BOOL)backgroundMode
                   priority:(ZADownloadModelPriroity)priority
                   progress:(ZADownloadProgressBlock)progressBlock
                 completion:(ZADownloadCompletionBlock)completionBlock
                    failure:(ZADownloadErrorBlock)errorBlock {
    /// Create directory if need
    [NSFileManager createDirectoryAtDocumentsIfNeedWithName:directoryName];
    NSURL *destinationUrl = [[DOCUMENT_URL appendName:directoryName] appendName:[urlString lastPathComponent]];
    
    [self downloadFileWithURL:urlString
               destinationUrl:destinationUrl
         enableBackgroundMode:backgroundMode
                   retryCount:DEFAULT_RETRY_COUNT
                retryInterval:DEFAULT_RETRY_INTERVAL
                     priority:priority
                     progress:progressBlock
                   completion:completionBlock
                      failure:errorBlock];
}

- (void)downloadFileWithURL:(NSString *)urlString
                   progress:(ZADownloadProgressBlock)progressBlock
                 completion:(ZADownloadCompletionBlock)completionBlock
                    failure:(ZADownloadErrorBlock)errorBlock {
    [self downloadFileWithURL:urlString
                directoryName:nil
         enableBackgroundMode:YES
                     priority:ZADownloadModelPriroityMedium
                     progress:progressBlock
                   completion:completionBlock
                      failure:errorBlock];
}

- (void)downloadFileWithRequestItem:(ZARequestItem *)requestItem
                         retryCount:(NSUInteger)retryCount
                      retryInterval:(NSUInteger)retryInterval {
    dispatch_async(_serialQueue, ^{
        
        /// Nếu item này đã tải xong và nằm trong thư mục TEMP thì copy đến destinationDirectory
        /// Sau đó bắn completion và return
        if (requestItem.isExistedOnTempDirectory) {
            NSURL *tempFileUrl = [TEMP_URL URLByAppendingPathComponent:requestItem.fileName];
            [[NSFileManager defaultManager] copyItemAtURL:tempFileUrl toURL:requestItem.destinationUrl error:nil];
            if (requestItem.completionBlock) {
                ZADownloadCompletionBlock completion = requestItem.completionBlock;
                dispatch_async(self.concurrentQueue, ^{
                    completion(requestItem.destinationUrl);
                });
            }
            return;
        }
        
        /// Nếu item chưa nằm trong TEMP
        /// Check thử item này đã được download rồi, hoặc đang download, hoặc đã được push vào queue hay chưa
        ZACommonDownloadItem *existedDownloadItem = [self _getZACommonDownloadItemWithRequestItem:requestItem];
        
        /// Nếu item mày muốn download đã tồn tại rồi (đang download or somethingelse)
        if (existedDownloadItem) {
            
            /// Nếu commonItem đã tồn tại rồi, thì update lại commonPriority
            if (requestItem.priority > existedDownloadItem.commonPriority) {
                existedDownloadItem.commonPriority = requestItem.priority;
            }
            
            /// Tùy vào commonState mà handle khác nhau:
            switch (existedDownloadItem.commonState) {
                case ZADownloadItemStateDownloading:
                {
                    /// Nếu common item đang download thì subItem chỉ cần mark nó đang download là được
                    /// Add nó vào commonItem đợi khi nào common item download xong nó sẽ foward lại cho all subitems.
                    requestItem.state = ZADownloadItemStateDownloading;
                    [existedDownloadItem addRequestItem:requestItem];
                    return;
                    break;
                }
                    
                case ZADownloadItemStatePaused:
                {
                    /// Nếu commonItem đang pause mà có 1 subItem cần download
                    /// Thì check coi có thể start được 1 downloadTask hay không
                    if ([self _canStartADownloadItem]) {
                        /// Nếu có thể start 1 downloadTask thì giả bộ add 1 paused-subitem vào commonItem
                        requestItem.state = ZADownloadItemStatePaused;
                        [existedDownloadItem addRequestItem:requestItem];
                        
                        /// Sau đó resume commonItem with subItem-Id
                        if (requestItem.backgroundMode) {
                            [existedDownloadItem resumeDownloadingWithRequestId:requestItem.requestId urlSession:self.backgroundURLSession];
                        } else {
                            [existedDownloadItem resumeDownloadingWithRequestId:requestItem.requestId urlSession:self.forcegroundURLSession];
                        }
                    } else {
                        
                        ///Nếu manager không cho phép start 1 download mới mà subItem đòi download
                        /// Thì add subItem vào pending queue
                        /// Update lại data cho commonItem và subitem trước
                        requestItem.state = ZADownloadItemStatePending;
                        existedDownloadItem.commonState = ZADownloadItemStatePending;
                        [existedDownloadItem addRequestItem:requestItem];
                                                
                        ///Add vào pending list
                        [self _addToPendingList:existedDownloadItem];
                    }
                    
                    break;
                }
                    
                case ZADownloadItemStatePending:
                {
                    /// Nếu commonItem đang nằm trong pendingList:
                    /// Thì đổi state thành pending thôi, add subItem vào commonItem
                    requestItem.state = ZADownloadItemStatePending;
                    [existedDownloadItem addRequestItem:requestItem];
                    break;
                }
                    
                default:
                    NSAssert(NO, @"Chưa handle state này");
                    break;
            }
            
            /// Thấy chỗ này sai sai rầu
            /// Để viết unit test rồi sửa lại chỗ này sau
            /// StartDownload hoặc add vào list pending tương ứng
            if ([self _canStartADownloadItem]) {
                self.totalDownloadingUrls++;
                [existedDownloadItem startDownloadingRequest:requestItem.requestId];
            } else {
                [self _addToPendingList:existedDownloadItem];
            }
            
        } else {
            /// Trường hợp ITEM mới tinh, chưa download lần nào:
            /// Create DownloadTask for CommonDownloadnItem.
            NSURLSessionDownloadTask *downloadTask = [self _downloadTaskWithRequestItem:requestItem];
            
            /// Create new CommonDownloadItem:
            ZACommonDownloadItem *commonDownloadItem = [[ZACommonDownloadItem alloc] initWithRequestItem:requestItem];
            commonDownloadItem.commonDownloadTask = downloadTask;
            commonDownloadItem.retryCount = retryCount;
            commonDownloadItem.retryInterval = retryInterval;
            
            /// Add to dictionary:
            if (requestItem.backgroundMode) {
                [self.backgroundDownloadItemsDict setObject:commonDownloadItem forKey:requestItem.urlString];
            } else {
                [self.foregroundDownloadItemsDict setObject:commonDownloadItem forKey:requestItem.urlString];
            }
            
            /// Start or Pending:
            if ([self _canStartADownloadItem]) {
                self.totalDownloadingUrls++;
                [commonDownloadItem startDownloadingRequest:requestItem.requestId];
            } else {
                [self _addToPendingList:commonDownloadItem];
            }
        }
    });
}

- (void)downloadImageWithUrl:(NSString *)urlString
                  completion:(void (^)(UIImage *, NSURL *))completionBlock
                     failure:(void (^)(NSError *))errorBlock {
    
    /// Check LDImageCache và return nếu có
    UIImage *cachedImage = [LDImageCache.shared getImageById:urlString];
    if (cachedImage) {
        ifnot (completionBlock) return;
        completionBlock(cachedImage,nil);
        return;
    }
    
    /// Nếu cache không có thì gọi download thôi:
    NSString *directoryName = IMAGE_DIRECTORY_NAME;
    [ZADownloadManager.sharedZADownloadManager downloadFileWithURL:urlString
                                                     directoryName:directoryName
                                              enableBackgroundMode:NO
                                                          priority:ZADownloadModelPriroityHigh
                                                          progress:nil
                                                        completion:^(NSURL *destinationUrl) {
        /// Load imageDownload được lên và cache lại:
        UIImage *downloadedImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:destinationUrl]];
        
        /// Cache downloadedImage
        if (downloadedImage) {
            [LDImageCache.shared cacheImage:downloadedImage byId:urlString];
            if (completionBlock) {
                completionBlock(downloadedImage,destinationUrl);
            }
        }
    } failure:^(NSError *error) {
        if (errorBlock) {
            errorBlock(error);
        }
    }];
}

- (void)downloadFileWithRequestItem:(ZARequestItem *)requestItem {
    [self downloadFileWithRequestItem:requestItem
                           retryCount:DEFAULT_RETRY_COUNT
                        retryInterval:DEFAULT_RETRY_INTERVAL];
}

- (void)pauseDownloadingOfRequest:(ZARequestItem *)requestItem {
    dispatch_async(_serialQueue, ^{
        
        /// Get CommonDownloadItem will be paused.
        ZACommonDownloadItem *commonItem = [self _getZACommonDownloadItemWithRequestItem:requestItem];
        NSAssert(commonItem != nil, @"requestItem is not existed in queue");
        
        /// Pause subItem with Identifier.
        [commonItem pauseDownloadingWithRequestId:requestItem.requestId];
        
        ///Nếu commonItem cũng bị pause theo, thì giảm totalDownloadingUrls
        if (commonItem.totalDownloadingSubItems == 0) {
            self.totalDownloadingUrls--;
        }
        
        ///Start 1 thằng đang pending nếu được
        [self _startHighestPriorityZADownloadItem];
    });
}

- (void)resumeDownloadingOfRequest:(ZARequestItem *)requestItem {
    dispatch_async(_serialQueue, ^{
        if ([self _canStartADownloadItem]) {
            /// Nếu queue đang free và có thể start resume
            /// Get commonItem:
            ZACommonDownloadItem *commonDownloadItem = [self _getZACommonDownloadItemWithRequestItem:requestItem];
            
            /// Resume
            if (commonDownloadItem.backgroundMode) {
                [commonDownloadItem resumeDownloadingWithRequestId:requestItem.requestId urlSession:self.backgroundURLSession];
            } else {
                [commonDownloadItem resumeDownloadingWithRequestId:requestItem.requestId urlSession:self.forcegroundURLSession];
            }
        } else {
            /// Bắn error như vầy là sai rồi
            /// TODO: fix it
            /// if over max concurrent.
            ZADownloadErrorBlock errorBlock = requestItem.errorBlock;
            NSError *error = [[NSError alloc] initWithDomain:@"duydl.DownloadManagerDomain" code:DownloadErrorCodeOverMaxConcurrentDownloads userInfo:nil];
            dispatch_async(self.concurrentQueue, ^{
                errorBlock(error);
            });
        }
    });
}

- (void)retryDownloadingOfRequestItem:(ZARequestItem *)requestItem {
    
    /// Get CommonDownloadItem will be Retry.
    ZACommonDownloadItem *downloadItem = [self _getZACommonDownloadItemWithRequestItem:requestItem];
    
    if (downloadItem.commonResumeData) {
        [self resumeDownloadingOfRequest:requestItem];
    } else {
        /// Nếu không có resumeData
        _totalDownloadingUrls++;
        if (requestItem.backgroundMode) {
            [downloadItem resumeDownloadingWithRequestId:requestItem.requestId urlSession:self.backgroundURLSession];
        } else {
            [downloadItem resumeDownloadingWithRequestId:requestItem.requestId urlSession:self.forcegroundURLSession];
        }
    }
}

- (void)cancelDownloadingOfRequest:(ZARequestItem *)requestItem {
    dispatch_async(_serialQueue, ^{
        
        /// Cancel common item
        ZACommonDownloadItem *commonItem = [self _getZACommonDownloadItemWithRequestItem:requestItem];
        [commonItem cancelDownloadingWithRequestId:requestItem.requestId];
        
        /// TODO: Refactor
        if (commonItem.requestItemsDict.count == 0) {
            
            if (commonItem.commonState == ZADownloadItemStateDownloading) {
                self.totalDownloadingUrls--;
            }
            
            if (requestItem.backgroundMode) {
                [self.backgroundDownloadItemsDict removeObjectForKey:requestItem.urlString];
            } else {
                [self.foregroundDownloadItemsDict removeObjectForKey:requestItem.urlString];
            }
        }
        
        /// Remove Item out of WaitingLists.
        if (commonItem.commonState == ZADownloadItemStatePending) {
            [self _removePendingDownloadItem:commonItem];
        }
        
        /// Resume a waiting downloadmodel.
        [self _startHighestPriorityZADownloadItem];
    });
}

# pragma mark - NSURLSessionDelegate

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    /// notify progress when downloading.
    /// get urlString, downloadItem from downloadTask.
    NSString *urlString = downloadTask.originalRequest.URL.absoluteString;
    if (!urlString) {
        urlString = downloadTask.currentRequest.URL.absoluteString;
    }
    ZACommonDownloadItem *downloadItem = nil;
    if ([downloadTask.description containsString:@"Background"]) {
        downloadItem = [self.backgroundDownloadItemsDict objectForKey:urlString];
    } else {
        downloadItem = [self.foregroundDownloadItemsDict objectForKey:urlString];
    }
    
    /// cancel old task.
    if (downloadTask.taskIdentifier != downloadItem.commonDownloadTask.taskIdentifier) {
        [downloadTask cancel];
        return;
    }
    
    for (ZARequestItem *subDownloadItem in downloadItem.requestItemsDict.allValues) {
        if (subDownloadItem.progressBlock && subDownloadItem.state == ZADownloadItemStateDownloading) {
            CGFloat progress = (CGFloat)totalBytesWritten/ (CGFloat)totalBytesExpectedToWrite;
            NSUInteger remainingTime = [self _remainingTimeForDownload:downloadItem bytesTransferred:totalBytesWritten totalBytesExpectedToWrite:totalBytesExpectedToWrite];
            NSUInteger speed = bytesWritten/1024;
            dispatch_async(dispatch_get_main_queue(), ^{
                subDownloadItem.progressBlock(progress, speed, remainingTime);
            });
        }
    }
    
}

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location {
    /// finished downlad file, which is stored as a temporary file in NSURL location.
    /// Get Completed ZADownloadModel.
    NSString *urlString = downloadTask.currentRequest.URL.absoluteString;
    if (!urlString) {
        urlString = downloadTask.originalRequest.URL.absoluteString;
    }
    
    ZACommonDownloadItem *commonDownloadItem = nil;
    if ([downloadTask.description containsString:@"Background"]) {
        commonDownloadItem = [self.backgroundDownloadItemsDict objectForKey:urlString];
    } else {
        commonDownloadItem = [self.foregroundDownloadItemsDict objectForKey:urlString];
    }
    
    if (commonDownloadItem) {
        NSError *error;
        NSURL *tempUrl;
        
        /// Copy files to all RequestItem.DestinationUrl:
        for (ZARequestItem *requestItem in commonDownloadItem.requestItemsDict.allValues) {
            
            /// If subModel is downloading ~ move to it's destination.
            if (requestItem.state == ZADownloadItemStateDownloading) {
                
                /// copy to TEMP Dir
                tempUrl = [TEMP_URL URLByAppendingPathComponent:[urlString lastPathComponent]];
                ifnot ([TEMP_URL containFileName:[urlString lastPathComponent]]) {
                    [[NSFileManager defaultManager] copyItemAtURL:location toURL:tempUrl error:&error];                             // copy to TEMP
                }
                
                /// copy to DESTINATION Url.
                [[NSFileManager defaultManager] copyItemAtURL:location toURL:requestItem.destinationUrl error:&error];          // copy to DESTINATION.
                
                /// callback
                ZADownloadCompletionBlock completion = requestItem.completionBlock;
                if (completion) {
                    dispatch_async(_concurrentQueue, ^{
                        completion(requestItem.destinationUrl);
                    });
                }
                
                // remove Download Completed RequestItem:
                [commonDownloadItem removeARequestItem:requestItem];
            }
        }
        
        /// Check If is existed a Paused RequestItem.
        /// -> Don't remove out of Dictionary.
        if (commonDownloadItem.requestItemsDict.allKeys.count == 0) {
            if (commonDownloadItem.backgroundMode) {
                [_backgroundDownloadItemsDict removeObjectForKey:urlString];
            } else {
                [_foregroundDownloadItemsDict removeObjectForKey:urlString];
            }
        }
        
        /// resume a waiting download.
        [self _startHighestPriorityZADownloadItem];
    } else {
        /// old downloadtask run success when user opens the app.
        /// so, it's not exist any DownloadModel in Dictionary.
        [downloadTask cancel];
    }
}

- (void)URLSession:(NSURLSession *)session
               task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error {
    /// called when user pause, cancle, loss connection,.....
    /// download success:
    ifnot (error) return;
    
    /// error cases:
    /// get model which has error.
    NSString *urlString = task.currentRequest.URL.absoluteString;
    ifnot (urlString) {
        urlString = task.originalRequest.URL.absoluteString;
    }
    
    ZACommonDownloadItem *commonDownloadItem = nil;
    if ([task.description containsString:@"Background"]) {
        commonDownloadItem = [self.backgroundDownloadItemsDict objectForKey:urlString];
    } else {
        commonDownloadItem = [self.foregroundDownloadItemsDict objectForKey:urlString];
    }
    
    /// handle erros:
    switch (error.code) {
            /// canceled/paused a task
        case -999:
        {
            return;
            break;
        }
            
            /// No connection.
        case -1009:
        {
            _totalDownloadingUrls--;
            [commonDownloadItem pauseAlls];
            
            // retry:
            if (commonDownloadItem.retryCount>0) {
                NSLog(@"dld: No connection,retryInterval: %lu, remaining retries: %lu",commonDownloadItem.retryInterval,commonDownloadItem.retryCount);
                commonDownloadItem.retryCount--;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(commonDownloadItem.retryInterval * NSEC_PER_SEC)), _serialQueue, ^{
                    [self _retryDownloadingOfCommonDownloadItem:commonDownloadItem withUrlString:urlString];
                });
                return;
            }
            
            /// retry failed alls, so callback error:
            commonDownloadItem.commonState = ZADownloadItemStateInterrupted;
            [commonDownloadItem resetRetryCount];
            
            for (ZARequestItem *requestItem in commonDownloadItem.requestItemsDict.allValues) {
                if (requestItem.errorBlock) {
                    NSError *error = [[NSError alloc] initWithDomain:@"duydl.DownloadManagerDomain" code:DownloadErrorCodeNoConnection userInfo:nil];
                    ZADownloadErrorBlock errorBlock = requestItem.errorBlock;
                    dispatch_async(self.concurrentQueue, ^{
                        errorBlock(error);
                    });
                }
            }
            return;
            break;
        }
            /// downloading -> timeout request (loss connection).
        case -1001:
        {
            /// retry:
            NSLog(@"dld: Before decrese total Active Urls = %lu",_totalDownloadingUrls);
            _totalDownloadingUrls--;
            if (commonDownloadItem.retryCount>0) {
                NSLog(@"dld: Loss connection,retryInterval: %lu, remaining retries: %lu",commonDownloadItem.retryInterval,commonDownloadItem.retryCount);
                commonDownloadItem.retryCount--;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(commonDownloadItem.retryInterval * NSEC_PER_SEC)), _serialQueue, ^{
                    //[self retryDowloadingOfUrl:urlString];
                });
                return;
            }
            
            return;
            break;
        }
        default:
            break;
    }
}

- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session {
    /// notify when all task downloads is done in backgrounds, move files done, forward completionCallbacks done.
    dispatch_async(dispatch_get_main_queue(), ^{
        AppDelegate *appDelegate = (AppDelegate*) UIApplication.sharedApplication.delegate;
        appDelegate.backgroundSessionCompleteHandler();
        appDelegate.backgroundSessionCompleteHandler = nil;
    });
}

#pragma mark - Observer

- (void)reachabilityChanged:(NSNotification *)note {
    Reachability* reachability = [note object];
    NetworkStatus netStatus = [reachability currentReachabilityStatus];
    if (netStatus == ReachableViaWiFi) {
        [self _resumeInterruptedDownloads];
    }
}

#pragma mark - Private methods

- (void)_retryDownloadingOfCommonDownloadItem:(ZACommonDownloadItem*)commonDownloadItem withUrlString:(NSString *)urlString {
    if (commonDownloadItem.commonResumeData) {
        /// TODO: ???
    } else {
        [commonDownloadItem.commonDownloadTask cancel];
        
        NSURL *url = [NSURL URLWithString:urlString];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
        NSURLSessionDownloadTask *downloadTask;
        
        if (commonDownloadItem.backgroundMode) {
            downloadTask = [self.backgroundURLSession downloadTaskWithRequest:request];
        } else {
            downloadTask = [self.forcegroundURLSession downloadTaskWithRequest:request];
        }
        
        commonDownloadItem.commonDownloadTask = downloadTask;
        _totalDownloadingUrls++;
        [commonDownloadItem startDownloadingAllRequests];
    }
}

- (ZACommonDownloadItem *)_getZACommonDownloadItemWithRequestItem:(ZARequestItem *)requestItem {
    ZACommonDownloadItem *item = nil;
    if (requestItem.backgroundMode) {
        item = [self.backgroundDownloadItemsDict objectForKey:requestItem.urlString];
    } else {
        item = [self.foregroundDownloadItemsDict objectForKey:requestItem.urlString];
    }
    return  item;
}

- (BOOL)_canStartADownloadItem {
    if (_maxConcurrentDownloads == NO_LIMIT_CONCURRENT_DOWNLOADS || (self.totalDownloadingUrls < _maxConcurrentDownloads)) {
        return true;
    }
    return false;
}

- (ZACommonDownloadItem *)_getHighestPriorityZADownloadModel {
    ZACommonDownloadItem *highestPriorityDownloadItem = nil;
    
    highestPriorityDownloadItem = [self.highPriorityDownloadItems firstObject];
    if (highestPriorityDownloadItem) {
        [self.highPriorityDownloadItems removeObject:highestPriorityDownloadItem];
        return highestPriorityDownloadItem;
    }
    
    highestPriorityDownloadItem = [self.mediumPriorityDownloadItems firstObject];
    if (highestPriorityDownloadItem) {
        [self.mediumPriorityDownloadItems removeObject:highestPriorityDownloadItem];
        return highestPriorityDownloadItem;
    }
    highestPriorityDownloadItem = [self.lowPriorityDownloadItems firstObject];
    if (highestPriorityDownloadItem) {
        [self.lowPriorityDownloadItems removeObject:highestPriorityDownloadItem];
        return highestPriorityDownloadItem;
    }
    return nil;
}

- (void)_startHighestPriorityZADownloadItem {
    if ([self _canStartADownloadItem]) {
        ZACommonDownloadItem *downloadItem = [self _getHighestPriorityZADownloadModel];
        if (downloadItem) {
            self.totalDownloadingUrls++;
            [downloadItem startAllPendingRequestItems];
        }
    }
}

- (void)_resumeInterruptedDownloads {
    /// TODO: complete it
}

- (void)_removePendingDownloadItem:(ZACommonDownloadItem*)downloadItem {
    switch (downloadItem.commonPriority) {
        case ZADownloadModelPriroityHigh:
            [_highPriorityDownloadItems removeObject:downloadItem];
            break;
        case ZADownloadModelPriroityMedium:
            [_mediumPriorityDownloadItems removeObject:downloadItem];
            break;
        case ZADownloadModelPriroityLow:
            [_lowPriorityDownloadItems removeObject:downloadItem];
            break;
    }
}

- (void)_addToPendingList:(ZACommonDownloadItem *)downloadItem {
    downloadItem.commonState = ZADownloadItemStatePending;
    
    switch (downloadItem.commonPriority) {
        case ZADownloadModelPriroityHigh:
            [self.highPriorityDownloadItems addObject:downloadItem];
            break;
        case ZADownloadModelPriroityMedium:
            [self.mediumPriorityDownloadItems addObject:downloadItem];
            break;
        case ZADownloadModelPriroityLow:
            [self.lowPriorityDownloadItems addObject:downloadItem];
            break;
        default:
            break;
    }
}

#pragma mark - Getter/Setter

- (NSURLSession *)backgroundURLSession {
    ifnot (_backgroundURLSession) {
        // backgroundSession alway waits for connectivity.
        NSURLSessionConfiguration *backgroundConfig = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:@"duydl.DownloadManager.backgroundsession"];
        backgroundConfig.discretionary = true;
        backgroundConfig.sessionSendsLaunchEvents = true;
        _backgroundURLSession = [NSURLSession sessionWithConfiguration:backgroundConfig delegate:self delegateQueue:nil];
    }
    
    return _backgroundURLSession;
}

- (NSURLSession *)forcegroundURLSession {
    ifnot (_forcegroundURLSession) {
        NSURLSessionConfiguration *defaultConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
        //defaultConfig.waitsForConnectivity = true;  // waits for connectitity, don't notify error immediately.
        defaultConfig.timeoutIntervalForRequest = TIMEOUT_INTERVAL_FOR_REQUEST;
        _forcegroundURLSession = [NSURLSession sessionWithConfiguration:defaultConfig delegate:self delegateQueue:nil];
    }
    return _forcegroundURLSession;
}

#pragma mark - Helper

- (BOOL)_isValidUrlString:(NSString *)urlString {
    NSURL *url = [NSURL URLWithString:urlString];
    BOOL isValid = url && [url scheme] && [url host];
    return isValid;
}

- (NSUInteger)_remainingTimeForDownload:(ZACommonDownloadItem *)downloadItem
                       bytesTransferred:(int64_t)bytesTransferred
              totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    NSTimeInterval timeInterval = [[NSDate date] timeIntervalSinceDate:downloadItem.startDate];
    CGFloat speed = (CGFloat)bytesTransferred / (CGFloat)timeInterval;
    CGFloat remainingBytes = totalBytesExpectedToWrite - bytesTransferred;
    CGFloat remainingTime = remainingBytes / speed;

    return (NSUInteger)remainingTime;
}

- (NSURLSessionDownloadTask *)_downloadTaskWithRequestItem:(ZARequestItem *)requestItem {
    NSURL *url = [NSURL URLWithString:requestItem.urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    NSURLSessionDownloadTask *downloadTask;
    if (requestItem.backgroundMode) {
        downloadTask = [self.backgroundURLSession downloadTaskWithRequest:request];
    } else {
        downloadTask = [self.forcegroundURLSession downloadTaskWithRequest:request];
    }
    return downloadTask;
}

@end
