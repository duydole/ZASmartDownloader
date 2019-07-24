#import "ZADownloadManager.h"
#import "ZACommonDownloadItem.h"
#import <UIKit/UIKit.h>
#import "AppDelegate.h"
#import "ZAImageCache.h"
#import "Reachability.h"

#define IMAGE_DIRECTORY_NAME @"Downloaded Images"
#define TIMEOUT_INTERVAL_FOR_REQUEST 10


@interface ZADownloadManager() <NSURLSessionDelegate, NSURLSessionDownloadDelegate>

@property (nonatomic) NSURLSession *forcegroundURLSession;                      // manage downloadtasks on forceground.
@property (nonatomic) NSURLSession *backgroundURLSession;                       // manage downloadtasks in background.
@property (nonatomic) dispatch_queue_t fileDownloaderSerialQueue;               // serial queue.
@property (nonatomic) NSURL *defaultDownloadedFilesDirectoryUrl;                // default directory for storing downloaded files.
@property (nonatomic) Reachability *internetReachability;                       // internet Reachability.
@property (nonatomic) NSUInteger totalDownloadingUrls;

@property (nonatomic) NSMutableDictionary *downloadItemDict;                   // all current zaDownloadModels.

@property (nonatomic) NSMutableDictionary *backgroundDownloadItemsDict;         // background DownloadItems.
@property (nonatomic) NSMutableDictionary *foregroundDownloadItemsDict;         // foreground DownloadItems.

@property (nonatomic) NSMutableArray *highPriorityDownloadItems;
@property (nonatomic) NSMutableArray *mediumPriorityDownloadItems;
@property (nonatomic) NSMutableArray *lowPriorityDownloadItems;

@end

@implementation ZADownloadManager

+ (instancetype) sharedInstance {
    static ZADownloadManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype) init {
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (void) setup {
    self.downloadItemDict = [[NSMutableDictionary alloc] init];
    _fileDownloaderSerialQueue = dispatch_queue_create("duydl.DownloadManager.SerialQueue", DISPATCH_QUEUE_SERIAL);
    _maxConcurrentDownloads = -1; // no limit.
    NSError *error = nil;
    _defaultDownloadedFilesDirectoryUrl = [NSFileManager.defaultManager URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:false error:&error];
    
    // setup reachability:
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
    self.internetReachability = [Reachability reachabilityForLocalWiFi];
    [self.internetReachability startNotifier];
    
    // number of downloading urls:
    _totalDownloadingUrls = 0;
    
    // priority lists:
    _highPriorityDownloadItems = [[NSMutableArray alloc] init];
    _mediumPriorityDownloadItems = [[NSMutableArray alloc] init];
    _lowPriorityDownloadItems = [[NSMutableArray alloc] init];
    
    // downloadItems dict:
    _backgroundDownloadItemsDict = [[NSMutableDictionary alloc] init];
    _foregroundDownloadItemsDict = [[NSMutableDictionary alloc] init];
}

- (NSURLSession*) backgroundURLSession {
    if (!_backgroundURLSession) {
        // backgroundSession alway waits for connectivity.
        NSURLSessionConfiguration *backgroundConfig = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:@"duydl.DownloadManager.backgroundsession"];
        backgroundConfig.discretionary = true;
        backgroundConfig.sessionSendsLaunchEvents = true;
        _backgroundURLSession = [NSURLSession sessionWithConfiguration:backgroundConfig delegate:self delegateQueue:nil];
    }
    return _backgroundURLSession;
}

- (NSURLSession*) forcegroundURLSession {
    if(!_forcegroundURLSession) {
        NSURLSessionConfiguration *defaultConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
        //defaultConfig.waitsForConnectivity = true;  // waits for connectitity, don't notify error immediately.
        defaultConfig.timeoutIntervalForRequest = TIMEOUT_INTERVAL_FOR_REQUEST;
        _forcegroundURLSession = [NSURLSession sessionWithConfiguration:defaultConfig delegate:self delegateQueue:nil];
    }
    return _forcegroundURLSession;
}

#pragma mark - Public methods:
- (void) downloadFileWithRequestItem:(ZADownloadItem *)subDownloadItem {
    
    dispatch_async(_fileDownloaderSerialQueue, ^{
        
        // Get downloadItem in Dictionary:
        ZACommonDownloadItem *existedDownloadItem = nil;
        if (subDownloadItem.isBackgroundMode) {
            existedDownloadItem = [self.backgroundDownloadItemsDict objectForKey:subDownloadItem.urlString];
        } else {
            existedDownloadItem = [self.foregroundDownloadItemsDict objectForKey:subDownloadItem.urlString];
        }
        
        // If DownloadItem is existed in Dictionary.
        if (existedDownloadItem) {
            
            // add a DownloadItem (state:Downloading) ## WARNING.
            
            [existedDownloadItem addDownloadItem:subDownloadItem];
            
            switch (existedDownloadItem.commonState) {
                    
                // if existed model is downloading.
                case ZADownloadModelStateDowloading:
                    existedDownloadItem.totalDownloadingSubItems++;
                    return;
                    break;
                    
                case ZADownloadModelStatePaused:
                    subDownloadItem.state = ZADownloadModelStateDowloading;
                    if (subDownloadItem.isBackgroundMode) {
                        [existedDownloadItem resumeWithId:subDownloadItem.requestId urlSession:self.backgroundURLSession];
                    } else {
                        [existedDownloadItem resumeWithId:subDownloadItem.requestId urlSession:self.forcegroundURLSession];
                    }
                    break;
                
                case ZADownloadModelStatePending:
                    // update priority:
                    if (subDownloadItem.priority > existedDownloadItem.commonPriority) {
                        existedDownloadItem.commonPriority = subDownloadItem.priority;
                    }
                    subDownloadItem.state = ZADownloadModelStatePending;
                    break;
                    
                default:
                    break;
            }
            
            // check coi Start được ko?
            if ([self canStartADownloadItem]) {
                NSLog(@"dld: You can start this DownloadItem.");
                self.totalDownloadingUrls++;
                [existedDownloadItem startDownloadingRequest:subDownloadItem.requestId];
            } else {
                [self addToWaitingList:existedDownloadItem];
            }
            
        } else {
            
            // Create first model:
            existedDownloadItem = [[ZACommonDownloadItem alloc] initWithRequestItem:subDownloadItem];
            
            // create DownloadTask for CommonDownloadnItem.
            NSURL *url = [NSURL URLWithString:subDownloadItem.urlString];
            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
            NSURLSessionDownloadTask *downloadTask;
            if (subDownloadItem.isBackgroundMode) {
                downloadTask = [self.backgroundURLSession downloadTaskWithRequest:request];
            } else {
                downloadTask = [self.forcegroundURLSession downloadTaskWithRequest:request];
            }
            existedDownloadItem.downloadTask = downloadTask;
            
            // add to dictionary:
            if (subDownloadItem.isBackgroundMode) {
                [self.backgroundDownloadItemsDict setObject:existedDownloadItem forKey:subDownloadItem.urlString];
            } else {
                [self.foregroundDownloadItemsDict setObject:existedDownloadItem forKey:subDownloadItem.urlString];
            }
            
            // start or pending:
            if ([self canStartADownloadItem]) {
                self.totalDownloadingUrls++;
                [existedDownloadItem startDownloadingRequest:subDownloadItem.requestId];
            } else {
                [self addToWaitingList:existedDownloadItem];
            }
        }
    });
}

- (ZADownloadItem*) downloadFileWithURL:(NSString*)urlString
                        destinationUrl:(NSURL*)destinationUrl
                  enableBackgroundMode:(BOOL)backgroundMode
                            retryCount:(NSUInteger)retryCount
                         retryInterval:(NSUInteger)retryInterval
                              priority:(ZADownloadModelPriroity)priority
                              progress:(ZADownloadProgressBlock)progressBlock
                            completion:(ZADownloadCompletionBlock)completionBlock
                               failure:(ZADownloadErrorBlock)errorBlock {
    // check urlString:
    if (![self isValidUrl:urlString]) {
        if (errorBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSError *error = [[NSError alloc] initWithDomain:@"duydl.DownloadManagerDomain" code:DownloadErrorCodeInvalidUrl userInfo:nil];
                errorBlock(error);
            });
        }
        return nil;
    }
    
    // check retryCount:
    if (retryCount < 0) {
        retryCount = 0;
    }
    
    // check retryInterval:
    if (retryInterval < 0) {
        retryInterval = 0;
    }
    
    // check destinationUrl
    if (!destinationUrl) {
        destinationUrl = [[self getDefaultDownloadedFileDirectoryUrl] URLByAppendingPathComponent:[urlString lastPathComponent]];
    }
    
    // create RequestItem (subModel):
    ZADownloadItem *requestItem = [[ZADownloadItem alloc] initWithUrlString:urlString
                                                           isBackgroundMode:backgroundMode
                                                                   priority:priority
                                                             destinationUrl:destinationUrl
                                                                   progress:progressBlock
                                                                 completion:completionBlock
                                                                    failure:errorBlock];
    
    // Start to Download:
    [self downloadFileWithRequestItem:requestItem];
    
    return requestItem;
}

- (void) downloadFileWithURL:(NSString *)urlString
               directoryName:(NSString *)directoryName
        enableBackgroundMode:(BOOL)backgroundMode
                    priority:(ZADownloadModelPriroity)priority
                    progress:(ZADownloadProgressBlock)progressBlock
                  completion:(ZADownloadCompletionBlock)completionBlock
                     failure:(ZADownloadErrorBlock)errorBlock {
    
    [self downloadFileWithURL:urlString
               destinationUrl:nil
         enableBackgroundMode:backgroundMode
                   retryCount:3
                retryInterval:10
                     priority:priority
                     progress:progressBlock
                   completion:completionBlock
                      failure:errorBlock];
}

- (void) downloadFileWithURL:(NSString *)urlString
                    progress:(ZADownloadProgressBlock)progressBlock
                  completion:(ZADownloadCompletionBlock)completionBlock
                     failure:(ZADownloadErrorBlock)errorBlock {
    [self downloadFileWithURL:urlString
                directoryName:nil
         enableBackgroundMode:YES
                     priority:ZADownloadModelPriroityMedium
                     progress:progressBlock
                   completion:completionBlock failure:errorBlock];
}

- (void) downloadImageWithUrl:(NSString *)urlString
                   completion:(void (^)(UIImage *, NSURL *))completionBlock
                      failure:(void (^)(NSError *))errorBlock {
    
        NSString *directoryName = IMAGE_DIRECTORY_NAME;
        
        // check ImageCache:
        UIImage *cachedImage = [DownloadedImageCache.sharededInstance getImageById:urlString];
    
    // if existed in cache:
        if (cachedImage) {
            NSLog(@"dld: existed in Image cache. I'll forward for you.");
            if (completionBlock) {
                completionBlock(cachedImage,nil);
            }
            return;
        }
        
        // download by ZAFileDownloader
        [ZADownloadManager.sharedInstance downloadFileWithURL:urlString directoryName:directoryName enableBackgroundMode:NO priority:ZADownloadModelPriroityHigh progress:nil completion:^(NSURL *destinationUrl) {
            
            // load image
            UIImage *downloadedImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:destinationUrl]];
            
            // cache image
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

- (void) pauseDownloadingOfRequest:(ZADownloadItem *)requestItem {
    dispatch_async(_fileDownloaderSerialQueue, ^{
        // Get MODEL you want to pause.
        ZACommonDownloadItem *downloadItem = nil;
        if (requestItem.isBackgroundMode) {
            downloadItem = [self.backgroundDownloadItemsDict objectForKey:requestItem.urlString];
        } else {
            downloadItem = [self.foregroundDownloadItemsDict objectForKey:requestItem.urlString];
        }
        
        // pause subModel with Identifier.
        [downloadItem pauseWithId:requestItem.requestId];
        
        // resume 1 waiting download with highest priority.
        if (downloadItem.totalDownloadingSubItems == 0) {
            self.totalDownloadingUrls--;
            NSLog(@"dld: paused all subModels, total downloading urls: %lu",self.totalDownloadingUrls);
        }
        
        [self startHighestPriorityZADownloadItem];
    });
}

- (void) resumeDownloadingOfRequest:(ZADownloadItem *)requestItem {
    dispatch_async(_fileDownloaderSerialQueue, ^{
        // 1. Get MODEL you want to RESUME.
        ZACommonDownloadItem *downloadItem = nil;
        if (requestItem.isBackgroundMode) {
            downloadItem = [self.backgroundDownloadItemsDict objectForKey:requestItem.urlString];
        } else {
            downloadItem = [self.foregroundDownloadItemsDict objectForKey:requestItem.urlString];
        }
        
        // 2. Resume:
        if (downloadItem.backgroundMode) {
            [downloadItem resumeWithId:requestItem.requestId urlSession:self.backgroundURLSession];
        } else {
            [downloadItem resumeWithId:requestItem.requestId urlSession:self.forcegroundURLSession];
        }
        
    });
}

- (void) retryDowloadingOfUrl:(NSString *)urlString {
    // ZADownloadItem *downloadItem = [self.downloadItemDict objectForKey:urlString];
    // [self retryDownloadItem:downloadItem];
}

- (void) cancelDownloadingOfRequest:(ZADownloadItem *)requestItem {
    
    dispatch_async(_fileDownloaderSerialQueue, ^{
        
        // get MODEL:
        ZACommonDownloadItem *downloadItem = nil;
        if (requestItem.isBackgroundMode) {
            downloadItem = [self.backgroundDownloadItemsDict objectForKey:requestItem.urlString];
        } else {
            downloadItem = [self.foregroundDownloadItemsDict objectForKey:requestItem.urlString];
        }
        
        // CANCEL:
        [downloadItem cancelWithId:requestItem.requestId];
        
        // decrease total downloading urls:
        
        if (downloadItem.downloadItemsDict.count == 0) {
            
            if (downloadItem.commonState == ZADownloadModelStateDowloading) {
                
                self.totalDownloadingUrls--;
            
            }
            
            if (requestItem.isBackgroundMode) {
                
                [self.backgroundDownloadItemsDict removeObjectForKey:requestItem.urlString];
                
            } else {
                
                [self.foregroundDownloadItemsDict removeObjectForKey:requestItem.urlString];
                
            }
        
        }
        
        // remove Item out of WaitingLists.
        if (downloadItem.commonState == ZADownloadModelStatePending) {
            [self removeAWaitingDownloadItem:downloadItem];
        }

        // resume a waiting downloadmodel.
        [self startHighestPriorityZADownloadItem];
    });
}

- (NSURL*) getDefaultDownloadedFileDirectoryUrl {
    return _defaultDownloadedFilesDirectoryUrl;
}

- (NSURL*) getDefaultDownloadedImageDirectoryUrl {
    return [self.defaultDownloadedFilesDirectoryUrl URLByAppendingPathComponent:IMAGE_DIRECTORY_NAME];
}

- (ZADownloadModelState)getDownloadStateOfUrl:(NSString *)urlString {
    __block ZACommonDownloadItem *downloadItem = nil;
    dispatch_sync(_fileDownloaderSerialQueue, ^{
        downloadItem = [self.downloadItemDict objectForKey:urlString];
    });
    return downloadItem.commonState;
}

# pragma mark - NSURLSessionDelegate implementation:
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
    if (downloadTask.taskIdentifier != downloadItem.downloadTask.taskIdentifier) {
        [downloadTask cancel];
        return;
    }
    
    //
    for (ZADownloadItem *subDownloadItem in downloadItem.downloadItemsDict.allValues) {
        if (subDownloadItem.progressBlock && subDownloadItem.state == ZADownloadModelStateDowloading) {
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
    ZACommonDownloadItem *downloadItem = nil;
    if ([downloadTask.description containsString:@"Background"]) {
        downloadItem = [self.backgroundDownloadItemsDict objectForKey:urlString];
    } else {
        downloadItem = [self.foregroundDownloadItemsDict objectForKey:urlString];
    }
    
    // If existed:
    if (downloadItem) {
        
        NSError *error;
        
        // For each ZASubDownloadModel:
        for (ZADownloadItem *subDownloadItem in downloadItem.downloadItemsDict.allValues) {
            
            // If subModel is downloading ~ move to it's destination.
            if (subDownloadItem.state == ZADownloadModelStateDowloading) {
                
                NSLog(@"dld: move to des with name: %@",[subDownloadItem.destinationUrl lastPathComponent]);
                
                [[NSFileManager defaultManager] copyItemAtURL:location toURL:subDownloadItem.destinationUrl error:&error];
                
                // callback
                ZADownloadCompletionBlock completion = subDownloadItem.completionBlock;
        
                NSURL *destinationUrl = subDownloadItem.destinationUrl;
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(destinationUrl);
                });
                
                // remove:
                // [downloadItem.listDownloadRequests removeObject:subDownloadItem];
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
    ZACommonDownloadItem *downloadItem = [self.downloadItemDict objectForKey:urlString];
    
    // handle erros:
    switch (error.code) {
        // canceled/paused a task
        case -999:
            return;
            break;
        // No connection.
        case -1009:
            NSLog(@"dld: Before decrese total Active Urls = %lu",_totalDownloadingUrls);
            _totalDownloadingUrls--;
            
            // retry:
            if (downloadItem.retryCount>0) {
                NSLog(@"dld: No connection,retryInterval: %lu, remaining retries: %lu",downloadItem.retryInterval,downloadItem.retryCount);
                downloadItem.retryCount--;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(downloadItem.retryInterval * NSEC_PER_SEC)), _fileDownloaderSerialQueue, ^{
                    [self retryDowloadingOfUrl:urlString];
                });
                return;
            }
            
            // retry failed alls, so callback error:
            downloadItem.commonState = ZADownloadModelStateInterrupted;
            [downloadItem resetRetryCount];
//            if (downloadItem.listErrorBlock) {
//                NSError *error = [[NSError alloc] initWithDomain:@"duydl.DownloadManagerDomain" code:DownloadErrorCodeNoConnection userInfo:nil];
//                [downloadItem forwardAllErrorBlockWithError:error];
//            }
            return;
            break;
        // downloading -> timeout request (loss connection).
        case -1001:
//            // handle logic:
//            downloadItem.commonState = ZADownloadModelStateInterrupted;
//            if (error.userInfo[NSURLSessionDownloadTaskResumeData]) {
//                // save resume
//                downloadItem.resumeData = error.userInfo[NSURLSessionDownloadTaskResumeData];
//            } else {
//                NSError *error = [[NSError alloc] initWithDomain:@"duydl.DownloadManagerDomain" code:DownloadErrorCodeCannotBeResumed userInfo:nil];
//                if (downloadItem.listErrorBlock) {
//                    [downloadItem forwardAllErrorBlockWithError:error];
//                }
//                downloadItem.commonState = ZADownloadModelStateInterrupted;
//            }
            
            // retry:
            NSLog(@"dld: Before decrese total Active Urls = %lu",_totalDownloadingUrls);
            _totalDownloadingUrls--;
            if (downloadItem.retryCount>0) {
                NSLog(@"dld: Loss connection,retryInterval: %lu, remaining retries: %lu",downloadItem.retryInterval,downloadItem.retryCount);
                downloadItem.retryCount--;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(downloadItem.retryInterval * NSEC_PER_SEC)), _fileDownloaderSerialQueue, ^{
                    [self retryDowloadingOfUrl:urlString];
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

- (BOOL) isDowloadingUrl: (NSString*)urlString {
    ZACommonDownloadItem *download = [self.downloadItemDict objectForKey:urlString];
    if (download && download.commonState == ZADownloadModelStateDowloading) {
        return true;
    }
    return false;
}

- (BOOL) canStartADownloadItem {
    // can we start a waiting-download.
    if (_maxConcurrentDownloads == -1 || (self.totalDownloadingUrls < _maxConcurrentDownloads)) {
        return true;
    }
    return false;
}

- (ZACommonDownloadItem*) getHighestPriorityZADownloadModel {
    
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

- (void) startHighestPriorityZADownloadItem {
    if ([self canStartADownloadItem]) {
        // get max priority downloadmodel:
        ZACommonDownloadItem *downloadItem = [self getHighestPriorityZADownloadModel];
        if (downloadItem) {
            self.totalDownloadingUrls++;
            [downloadItem startAllPendingDownloadItems];
        }
    }
}

- (BOOL) isValidUrl: (NSString*)urlString {
    NSURL *url = [NSURL URLWithString:urlString];
    BOOL isValid = url && [url scheme] && [url host];
    return isValid;
}

- (void) reachabilityChanged: (NSNotification *)note {
    Reachability* reachability = [note object];
    NetworkStatus netStatus = [reachability currentReachabilityStatus];     // status of network.
    if (netStatus == ReachableViaWiFi) {
        [self resumeInterruptedDownloads];
    }
}

- (void) resumeInterruptedDownloads {
    for (ZACommonDownloadItem *downloadItem in _downloadItemDict.allValues) {
        if (downloadItem.commonState == ZADownloadModelStateInterrupted) {
            // [self retryDownloadItem:downloadItem];
        }
    }
}

- (NSUInteger) numberOfDownloadingUrls {
    __block NSUInteger total;
    dispatch_sync(_fileDownloaderSerialQueue, ^{
        total = self.totalDownloadingUrls;
    });
    return total;
}

- (void) removeAWaitingDownloadItem:(ZACommonDownloadItem*)downloadItem {
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

- (void) addToWaitingList:(ZACommonDownloadItem*)downloadItem {
    downloadItem.commonState = ZADownloadModelStatePending;               // waiting for download.
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

# pragma mark - Private methods: system file logics.
- (void) createDirectoryWithName:(NSString*)directoryName {
    NSFileManager *fileManager= [NSFileManager defaultManager];
    NSError *error = nil;
    [fileManager createDirectoryAtURL:[self.defaultDownloadedFilesDirectoryUrl URLByAppendingPathComponent:directoryName] withIntermediateDirectories:true attributes:nil error:&error];
}

- (BOOL) isExistedFile:(NSString*)fileName
           inDirectory:(NSString*)directoryName {
    NSURL *fileURL;
    if (directoryName) {
        fileURL = [[self.defaultDownloadedFilesDirectoryUrl URLByAppendingPathComponent:directoryName] URLByAppendingPathComponent:fileName];
    } else {
        fileURL = [self.defaultDownloadedFilesDirectoryUrl URLByAppendingPathComponent:fileName];
    }
    NSError *error = nil;
    return [fileURL checkResourceIsReachableAndReturnError:&error];
}

- (NSURL*) getFileUrlWithFileName:(NSString*)fileName
                    directoryName:(NSString*)directoryName {
    NSURL *fileUrl;
    if (directoryName) {
        [self createDirectoryWithName:directoryName];
        fileUrl = [[self.defaultDownloadedFilesDirectoryUrl URLByAppendingPathComponent:directoryName] URLByAppendingPathComponent:fileName];
    } else {
        fileUrl = [self.defaultDownloadedFilesDirectoryUrl URLByAppendingPathComponent:fileName];
    }
    return fileUrl;
}

@end
