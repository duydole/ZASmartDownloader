//
//  ZADownloadManager.m
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

#define IMAGE_DIRECTORY_NAME @"Downloaded Images"
#define DEFAUL_DOWNLOADED_DIRECTORY_NAME @"Downloaded Files"
#define TIMEOUT_INTERVAL_FOR_REQUEST 10
#define NO_LIMIT_CONCURRENT_DOWNLOADS -1
#define DEFAULT_RETRY_COUNT 3
#define DEFAULT_RETRY_INTERVAL 10

@interface ZADownloadManager() <NSURLSessionDelegate, NSURLSessionDownloadDelegate>

@property (nonatomic, strong) Reachability *internetReachability;
@property (nonatomic, assign) NSUInteger totalDownloadingUrls;

@property (nonatomic, strong) NSURLSession *forcegroundURLSession;
@property (nonatomic, strong) NSURLSession *backgroundURLSession;

@property (nonatomic, strong) dispatch_queue_t serialQueue;
@property (nonatomic, strong) dispatch_queue_t concurrentQueue;

@property (nonatomic, strong) NSMutableDictionary *backgroundDownloadItemsDict;
@property (nonatomic, strong) NSMutableDictionary *foregroundDownloadItemsDict;

@property (nonatomic, strong) NSMutableArray *highPriorityDownloadItems;
@property (nonatomic, strong) NSMutableArray *mediumPriorityDownloadItems;
@property (nonatomic, strong) NSMutableArray *lowPriorityDownloadItems;

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

- (void)downloadFileWithRequestItem:(ZARequestItem *)requestItem
                         retryCount:(NSUInteger)retryCount
                      retryInterval:(NSUInteger)retryInterval {
    dispatch_async(_serialQueue, ^{
        
        /// Nếu item này đã tải xong và nằm trong thư mục TEMP thì copy đến DestinationDirectory
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
        /// Check thử item này đã được download rồi và nằm chỗ nào đó hay chưa.
        ZACommonDownloadItem *existedDownloadItem = [self _getZACommonDownloadItemWithRequestItem:requestItem];
            
        /// Nếu item mày muốn download đã tồn tại rồi (đang download or somethingelse)
        if (existedDownloadItem) {
            
            ///State hiện tại của item này là:
            switch (existedDownloadItem.commonState) {
                case ZADownloadItemStateDownloading:
                {
                    requestItem.state = ZADownloadItemStateDownloading;
                    [existedDownloadItem addRequestItem:requestItem];
                    return;
                    break;
                }
                
                case ZADownloadItemStatePaused:
                {
                    // if can't start downloading:
                    if (![self canStartADownloadItem]) {
                        
                        // chuyển cả MODEL + subModel -> Pending
                        requestItem.state = ZADownloadItemStatePending;
                        existedDownloadItem.commonState = ZADownloadItemStatePending;
                        [existedDownloadItem addRequestItem:requestItem];
                        
                        // nếu priority của subModel > Model
                        if (requestItem.priority>existedDownloadItem.commonPriority) {
                            existedDownloadItem.commonPriority = requestItem.priority;
                            [self addToPendingList:existedDownloadItem];
                        }
                        
                    } else {
                        
                        // can start download:
                        
                        requestItem.state = ZADownloadItemStatePaused;          // assume that it's paused.
                        [existedDownloadItem addRequestItem:requestItem];
                        // resume:
                        if (requestItem.backgroundMode) {
                            [existedDownloadItem resumeDownloadingWithRequestId:requestItem.requestId urlSession:self.backgroundURLSession];
                        } else {
                            [existedDownloadItem resumeDownloadingWithRequestId:requestItem.requestId urlSession:self.forcegroundURLSession];
                        }
                    }
                    
                    break;
                }
                    
                case ZADownloadItemStatePending:
                {
                    if (requestItem.priority > existedDownloadItem.commonPriority) {
                        existedDownloadItem.commonPriority = requestItem.priority;
                    }
                    requestItem.state = ZADownloadItemStatePending;
                    [existedDownloadItem addRequestItem:requestItem];
                    break;
                }
                    
                default:
                    NSAssert(NO, @"Chưa handle state này");
                    break;
            }
            
            /// StartDownload hoặc add vào list pending tương ứng
            if ([self canStartADownloadItem]) {
                self.totalDownloadingUrls++;
                [existedDownloadItem startDownloadingRequest:requestItem.requestId];
            } else {
                [self addToPendingList:existedDownloadItem];
            }
            
        } else {
            /// Trường hợp ITEM mới tinh, chưa download lần nào:
            
            // Create new CommonDownloadItem:
            ZACommonDownloadItem *commonDownloadItem = [[ZACommonDownloadItem alloc] initWithRequestItem:requestItem];
            
            // create DownloadTask for CommonDownloadnItem.
            NSURL *url = [NSURL URLWithString:requestItem.urlString];
            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
            NSURLSessionDownloadTask *downloadTask;
            if (requestItem.backgroundMode) {
                downloadTask = [self.backgroundURLSession downloadTaskWithRequest:request];
            } else {
                downloadTask = [self.forcegroundURLSession downloadTaskWithRequest:request];
            }
            commonDownloadItem.commonDownloadTask = downloadTask;
            commonDownloadItem.retryCount = retryCount;
            commonDownloadItem.retryInterval = retryInterval;
            
            // add to dictionary:
            if (requestItem.backgroundMode) {
                [self.backgroundDownloadItemsDict setObject:commonDownloadItem forKey:requestItem.urlString];
            } else {
                [self.foregroundDownloadItemsDict setObject:commonDownloadItem forKey:requestItem.urlString];
            }
            
            // start or pending:
            if ([self canStartADownloadItem]) {
                self.totalDownloadingUrls++;
                [commonDownloadItem startDownloadingRequest:requestItem.requestId];
            } else {
                [self addToPendingList:commonDownloadItem];
            }
        }
    });
}

- (void)downloadFileWithRequestItem:(ZARequestItem *)requestItem {
    [self downloadFileWithRequestItem:requestItem
                           retryCount:DEFAULT_RETRY_COUNT
                        retryInterval:DEFAULT_RETRY_INTERVAL];
}

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
    ifnot ([self isValidUrl:urlString]) {
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
    ZARequestItem *requestItem = [[ZARequestItem alloc] initWithUrlString:urlString
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
    [self downloadFileWithURL:urlString
               destinationUrl:nil
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

- (void)downloadImageWithUrl:(NSString *)urlString
                  completion:(void (^)(UIImage *, NSURL *))completionBlock
                     failure:(void (^)(NSError *))errorBlock {
    
    /// Check Image-Cache và return nếu có
    UIImage *cachedImage = [DownloadedImageCache.sharededInstance getImageById:urlString];
    if (cachedImage) {
        NSLog(@"dld: existed in Image cache. I'll forward for you.");
        if (completionBlock) {
            completionBlock(cachedImage,nil);
        }
        return;
    }
    
    /// Nếu cache không có thì gọi download thôi:
    NSString *directoryName = IMAGE_DIRECTORY_NAME;
    [ZADownloadManager.sharedZADownloadManager downloadFileWithURL:urlString directoryName:directoryName enableBackgroundMode:NO priority:ZADownloadModelPriroityHigh progress:nil completion:^(NSURL *destinationUrl) {
        /// Load imageDownload được lên và cache lại:
        UIImage *downloadedImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:destinationUrl]];
        
        /// Cache downloadedImage
        if (downloadedImage) {
            [DownloadedImageCache.sharededInstance storeImage:downloadedImage byId:urlString];
            // call back image.
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

- (void)pauseDownloadingOfRequest:(ZARequestItem *)requestItem {
    dispatch_async(_serialQueue, ^{
        // 1. Get CommonDownloadItem will be paused.
        ZACommonDownloadItem *downloadItem = nil;
        if (requestItem.backgroundMode) {
            downloadItem = [self.backgroundDownloadItemsDict objectForKey:requestItem.urlString];
        } else {
            downloadItem = [self.foregroundDownloadItemsDict objectForKey:requestItem.urlString];
        }
        
        // 2. Pause subModel with Identifier.
        [downloadItem pauseDownloadingWithRequestId:requestItem.requestId];
        
        // resume 1 waiting download with highest priority.
        if (downloadItem.totalDownloadingSubItems == 0) {
            self.totalDownloadingUrls--;
            NSLog(@"dld: paused all subModels, total downloading urls: %lu",self.totalDownloadingUrls);
        }
        
        [self startHighestPriorityZADownloadItem];
    });
}

- (void)resumeDownloadingOfRequest:(ZARequestItem *)requestItem {
    dispatch_async(_serialQueue, ^{
        // if can resume
        if ([self canStartADownloadItem]) {
            // 1. Get MODEL you want to RESUME.
            ZACommonDownloadItem *commonDownloadItem = nil;
            if (requestItem.backgroundMode) {
                commonDownloadItem = [self.backgroundDownloadItemsDict objectForKey:requestItem.urlString];
            } else {
                commonDownloadItem = [self.foregroundDownloadItemsDict objectForKey:requestItem.urlString];
            }
            
            // 2. Resume:
            if (commonDownloadItem.backgroundMode) {
                [commonDownloadItem resumeDownloadingWithRequestId:requestItem.requestId urlSession:self.backgroundURLSession];
            } else {
                [commonDownloadItem resumeDownloadingWithRequestId:requestItem.requestId urlSession:self.forcegroundURLSession];
            }
        } else {
            // if over max concurrent.
            ZADownloadErrorBlock errorBlock = requestItem.errorBlock;
            NSError *error = [[NSError alloc] initWithDomain:@"duydl.DownloadManagerDomain" code:DownloadErrorCodeOverMaxConcurrentDownloads userInfo:nil];
            dispatch_async(self.concurrentQueue, ^{
                errorBlock(error);
            });
        }
    });
}

- (void)retryDownloadingOfRequestItem:(ZARequestItem *)requestItem {
    /// retry download of 1 REQUEST ITEM:

    // 1. Get CommonDownloadItem will be Retry.
    ZACommonDownloadItem *downloadItem = nil;
    if (requestItem.backgroundMode) {
        downloadItem = [self.backgroundDownloadItemsDict objectForKey:requestItem.urlString];
    } else {
        downloadItem = [self.foregroundDownloadItemsDict objectForKey:requestItem.urlString];
    }
    
    // if DownloadItem has ResumeData
    if (downloadItem.commonResumeData) {
        [self resumeDownloadingOfRequest: requestItem];
    } else {
        _totalDownloadingUrls++;
        if (requestItem.backgroundMode) {
            [downloadItem resumeDownloadingWithRequestId:requestItem.requestId urlSession:self.backgroundURLSession];
        } else {
            [downloadItem resumeDownloadingWithRequestId:requestItem.requestId urlSession:self.forcegroundURLSession];
        }
    }
}

- (void)retryDownloadingOfCommonDownloadItem:(ZACommonDownloadItem*)commonDownloadItem
                               withUrlString:(NSString *)urlString {
    
    if (commonDownloadItem.commonResumeData) {
        
    } else {
        
        [commonDownloadItem.commonDownloadTask cancel];
        
        // create download task
        
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

- (void)cancelDownloadingOfRequest:(ZARequestItem *)requestItem {
    
    dispatch_async(_serialQueue, ^{
        
        // get MODEL:
        ZACommonDownloadItem *downloadItem = nil;
        if (requestItem.backgroundMode) {
            downloadItem = [self.backgroundDownloadItemsDict objectForKey:requestItem.urlString];
        } else {
            downloadItem = [self.foregroundDownloadItemsDict objectForKey:requestItem.urlString];
        }
        
        // CANCEL:
        [downloadItem cancelDownloadingWithRequestId:requestItem.requestId];
        
        //
        if (downloadItem.requestItemsDict.count == 0) {
            
            if (downloadItem.commonState == ZADownloadItemStateDownloading) {
                self.totalDownloadingUrls--;
            }
            
            if (requestItem.backgroundMode) {
                [self.backgroundDownloadItemsDict removeObjectForKey:requestItem.urlString];
            } else {
                [self.foregroundDownloadItemsDict removeObjectForKey:requestItem.urlString];
            }
        }
        
        // remove Item out of WaitingLists.
        if (downloadItem.commonState == ZADownloadItemStatePending) {
            [self removeAWaitingDownloadItem:downloadItem];
        }
        
        // resume a waiting downloadmodel.
        [self startHighestPriorityZADownloadItem];
    });
}

- (NSURL *)getDefaultDownloadedFileDirectoryUrl {
    return DOCUMENT_URL;
}

- (NSURL *)getDefaultDownloadedImageDirectoryUrl {
    return [DOCUMENT_URL URLByAppendingPathComponent:IMAGE_DIRECTORY_NAME];
}

# pragma mark - NSURLSessionDelegate implementation

// notify progress when downloading.
- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    
    
    // get urlString, downloadItem from downloadTask.
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
    
    
    // cancel old task.
    if (downloadTask.taskIdentifier != downloadItem.commonDownloadTask.taskIdentifier) {
        [downloadTask cancel];
        return;
    }
    
    //
    for (ZARequestItem *subDownloadItem in downloadItem.requestItemsDict.allValues) {
        if (subDownloadItem.progressBlock && subDownloadItem.state == ZADownloadItemStateDownloading) {
            CGFloat progress = (CGFloat)totalBytesWritten/ (CGFloat)totalBytesExpectedToWrite;
            NSUInteger remainingTime = [self remainingTimeForDownload:downloadItem bytesTransferred:totalBytesWritten totalBytesExpectedToWrite:totalBytesExpectedToWrite];
            NSUInteger speed = bytesWritten/1024;
            dispatch_async(dispatch_get_main_queue(), ^{
                subDownloadItem.progressBlock(progress, speed, remainingTime);
            });
        }
    }
    
}

// finished downlad file, which is stored as a temporary file in NSURL location.
- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location {
    
    // Get Completed ZADownloadModel.
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
    
    // If existed:
    if (commonDownloadItem) {
        
        NSError *error;
        NSURL *tempUrl;
        
        // Copy files to all RequestItem.DestinationUrl:
        for (ZARequestItem *requestItem in commonDownloadItem.requestItemsDict.allValues) {
            
            // If subModel is downloading ~ move to it's destination.
            if (requestItem.state == ZADownloadItemStateDownloading) {
                
                // copy to TEMP Dir
                tempUrl = [TEMP_URL URLByAppendingPathComponent:[urlString lastPathComponent]];
                if (![self isExistedFileName:[urlString lastPathComponent] inDirectory:TEMP_URL]) {
                    [[NSFileManager defaultManager] copyItemAtURL:location toURL:tempUrl error:&error];                             // copy to TEMP
                }
                
                // copy to DESTINATION Url.
                [[NSFileManager defaultManager] copyItemAtURL:location toURL:requestItem.destinationUrl error:&error];          // copy to DESTINATION.
                
                // callback
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
        
        // Check If is existed a Paused RequestItem.
        // -> Don't remove out of Dictionary.
        if (commonDownloadItem.requestItemsDict.allKeys.count == 0) {
            if (commonDownloadItem.backgroundMode) {
                [_backgroundDownloadItemsDict removeObjectForKey:urlString];
            } else {
                [_foregroundDownloadItemsDict removeObjectForKey:urlString];
            }
        }
        
        // resume a waiting download.
        [self startHighestPriorityZADownloadItem];
    } else {
        // old downloadtask run success when user opens the app.
        // so, it's not exist any DownloadModel in Dictionary.
        [downloadTask cancel];
    }
}

// called when user pause, cancle, loss connection,.....
- (void) URLSession:(NSURLSession *)session
               task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error {
    // download success:
    if (!error) {
        return;
    }
    
    // error cases:
    // get model which has error.
    NSString *urlString = task.currentRequest.URL.absoluteString;
    if (!urlString) {
        urlString = task.originalRequest.URL.absoluteString;
    }
    
    ZACommonDownloadItem *commonDownloadItem = nil;
    if ([task.description containsString:@"Background"]) {
        commonDownloadItem = [self.backgroundDownloadItemsDict objectForKey:urlString];
    } else {
        commonDownloadItem = [self.foregroundDownloadItemsDict objectForKey:urlString];
    }
    
    // handle erros:
    switch (error.code) {
            // canceled/paused a task
        case -999:
            return;
            break;
            
            // No connection.
        case -1009:
            _totalDownloadingUrls--;
            [commonDownloadItem pauseAlls];
            
            // retry:
            if (commonDownloadItem.retryCount>0) {
                NSLog(@"dld: No connection,retryInterval: %lu, remaining retries: %lu",commonDownloadItem.retryInterval,commonDownloadItem.retryCount);
                commonDownloadItem.retryCount--;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(commonDownloadItem.retryInterval * NSEC_PER_SEC)), _serialQueue, ^{
                    [self retryDownloadingOfCommonDownloadItem:commonDownloadItem withUrlString:urlString];
                });
                return;
            }
            
            // retry failed alls, so callback error:
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
            
            // downloading -> timeout request (loss connection).
        case -1001:
            //            // handle logic:
            //            downloadItem.commonState = ZADownloadItemStateInterrupted;
            //            if (error.userInfo[NSURLSessionDownloadTaskResumeData]) {
            //                // save resume
            //                downloadItem.resumeData = error.userInfo[NSURLSessionDownloadTaskResumeData];
            //            } else {
            //                NSError *error = [[NSError alloc] initWithDomain:@"duydl.DownloadManagerDomain" code:DownloadErrorCodeCannotBeResumed userInfo:nil];
            //                if (downloadItem.listErrorBlock) {
            //                    [downloadItem forwardAllErrorBlockWithError:error];
            //                }
            //                downloadItem.commonState = ZADownloadItemStateInterrupted;
            //            }
            
            // retry:
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
            
            
            // retry failed alls, so callback error:
            //            [downloadItem resetRetryCount];
            //            if (downloadItem.listErrorBlock) {
            //                NSError *error = [[NSError alloc] initWithDomain:@"duydl.DownloadManagerDomain" code:DownloadErrorCodeTimeoutRequest userInfo:nil];
            //                [downloadItem forwardAllErrorBlockWithError:error];
            //            }
            return;
            break;
        default:
            break;
    }
    
    // other errors:
    // [downloadItem forwardAllErrorBlockWithError:error];
    // downloadItem.state = ZADownloadModelStateCancelled;
}

// notify when all task downloads is done in backgrounds, move files done, forward completionCallbacks done.
- (void) URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session {
    dispatch_async(dispatch_get_main_queue(), ^{
        AppDelegate *appDelegate = (AppDelegate*) UIApplication.sharedApplication.delegate;
        appDelegate.backgroundSessionCompleteHandler();
        appDelegate.backgroundSessionCompleteHandler = nil;
    });
}

# pragma mark - Private methods: handle logics.
- (NSUInteger) remainingTimeForDownload: (ZACommonDownloadItem*)downloadItem
                       bytesTransferred: (int64_t)bytesTransferred
              totalBytesExpectedToWrite: (int64_t)totalBytesExpectedToWrite {
    NSTimeInterval timeInterval = [[NSDate date] timeIntervalSinceDate:downloadItem.startDate];
    CGFloat speed = (CGFloat)bytesTransferred / (CGFloat)timeInterval;
    CGFloat remainingBytes = totalBytesExpectedToWrite - bytesTransferred;
    CGFloat remainingTime = remainingBytes / speed;
    return (NSUInteger) remainingTime;
}

- (BOOL)canStartADownloadItem {
    // can we start a waiting-download.
    if (_maxConcurrentDownloads == -1 || (self.totalDownloadingUrls < _maxConcurrentDownloads)) {
        return true;
    }
    return false;
}

- (ZACommonDownloadItem*)getHighestPriorityZADownloadModel {
    
    //NSLog(@"dld: Begin to choose highest priority item");
    
    //NSLog(@"dld: Before choosing item, HIGH: %lu items, MEDIUM: %lu items, LOW: %lu items",_highPriorityDownloadItems.count,_mediumPriorityDownloadItems.count,_lowPriorityDownloadItems.count);
    
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

- (void)startHighestPriorityZADownloadItem {
    if ([self canStartADownloadItem]) {
        // get max priority downloadmodel:
        ZACommonDownloadItem *downloadItem = [self getHighestPriorityZADownloadModel];
        if (downloadItem) {
            self.totalDownloadingUrls++;
            [downloadItem startAllPendingRequestItems];
        }
    }
}

- (BOOL)isValidUrl:(NSString *)urlString {
    NSURL *url = [NSURL URLWithString:urlString];
    BOOL isValid = url && [url scheme] && [url host];
    return isValid;
}

- (void)reachabilityChanged: (NSNotification *)note {
    Reachability* reachability = [note object];
    NetworkStatus netStatus = [reachability currentReachabilityStatus];     // status of network.
    if (netStatus == ReachableViaWiFi) {
        [self resumeInterruptedDownloads];
    }
}

- (void)resumeInterruptedDownloads {
    //    for (ZACommonDownloadItem *downloadItem in _downloadItemDict.allValues) {
    //        if (downloadItem.commonState == ZADownloadItemStateInterrupted) {
    //            // [self retryDownloadItem:downloadItem];
    //        }
    //    }
}

- (NSUInteger)numberOfDownloadingUrls {
    __block NSUInteger total;
    dispatch_sync(_serialQueue, ^{
        total = self.totalDownloadingUrls;
    });
    return total;
}

- (void)removeAWaitingDownloadItem:(ZACommonDownloadItem*)downloadItem {
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

- (void)addToPendingList:(ZACommonDownloadItem*)downloadItem {
    downloadItem.commonState = ZADownloadItemStatePending;               // waiting for download.
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

#pragma mark - Private methods: system file logics.

- (void)createDirectoryWithName:(NSString *)directoryName {
    NSFileManager *fileManager= [NSFileManager defaultManager];
    NSError *error = nil;
    [fileManager createDirectoryAtURL:[DOCUMENT_URL URLByAppendingPathComponent:directoryName] withIntermediateDirectories:true attributes:nil error:&error];
}

- (BOOL)isExistedFileName:(NSString *)fileName
              inDirectory:(NSURL *)directoryUrl {
    
    NSURL *fileURL;
    
    if (fileName) {
        fileURL = [directoryUrl URLByAppendingPathComponent:fileName];
    }
    
    NSError *error = nil;
    return [fileURL checkResourceIsReachableAndReturnError:&error];
}

- (NSURL *)getFileUrlWithFileName:(NSString *)fileName
                   directoryName:(NSString *)directoryName {
    NSURL *fileUrl;
    if (directoryName) {
        [self createDirectoryWithName:directoryName];
        fileUrl = [[DOCUMENT_URL URLByAppendingPathComponent:directoryName] URLByAppendingPathComponent:fileName];
    } else {
        fileUrl = [DOCUMENT_URL URLByAppendingPathComponent:fileName];
    }
    return fileUrl;
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


@end
