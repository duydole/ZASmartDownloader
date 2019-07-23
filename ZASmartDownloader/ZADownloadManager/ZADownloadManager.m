#import "ZADownloadManager.h"
#import "ZADownloadItem.h"
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
- (void) downloadFileWithURL:(NSString*)urlString
               directoryName:(NSString*)directoryName               // sửa thành destinationPath.
        enableBackgroundMode:(BOOL)backgroundMode
                  retryCount:(NSUInteger)retryCount
               retryInterval:(NSUInteger)retryInterval
                    priority:(ZADownloadModelPriroity)priority
                    progress:(ZADownloadProgressBlock)progressBlock
                  completion:(ZADownloadCompletionBlock)completionBlock
                     failure:(ZADownloadErrorBlock)errorBlock {
    // download:
    dispatch_async(_fileDownloaderSerialQueue, ^{
        
        // Get fileName:
        NSString *fileName = [urlString lastPathComponent];

        // Check valid url:
        if (![self isValidUrl:urlString]) {
            if (errorBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSError *error = [[NSError alloc] initWithDomain:@"duydl.DownloadManagerDomain" code:DownloadErrorCodeInvalidUrl userInfo:nil];
                    errorBlock(error);
                });
            }
            return;
        }
        
        // Check in dictionary:
        ZADownloadItem *existedDownloadItem = [self.downloadItemDict objectForKey:urlString];
        NSURL *destinationUrl = nil;
        if (existedDownloadItem) {
            switch (existedDownloadItem.state) {
                    
                // Url is downloading:
                case ZADownloadModelStateDowloading:
                    NSLog(@"dld: Other Bussiness is downloading, just wait....");
                    
                    // if downloading Item has the same directoryName
                    if ([existedDownloadItem.directoryName isEqualToString:directoryName]) {
                        
                        // gen newFileName
                        NSUInteger totalWaitingRequest = [existedDownloadItem totalWaitingRequest];
                        NSArray *array = [fileName componentsSeparatedByString:@"."];
                        NSString *fileType = [array lastObject];
                        fileName = array[0];
                        for (int i = 1; i < array.count-1; i++) {
                            fileName = [[NSString alloc] initWithFormat:@"%@.%@",fileName,array[i]];
                        }
                        fileName = [[NSString alloc] initWithFormat:@"%@ (%lu).%@",fileName,totalWaitingRequest,fileType];
                    }
                    
                    // get Destinarion Directory:
                    destinationUrl = [self getFileUrlWithFileName:fileName directoryName:directoryName];

                    // save completionBlock with destinationDir
                    [existedDownloadItem addCompletionBlock:completionBlock withDestinationUrl:destinationUrl];

                    // save completionBlock, errorBlock.
                    [existedDownloadItem addCompletionBlock:completionBlock];
                    [existedDownloadItem addErrorBlock:errorBlock];
                    [existedDownloadItem addProgressBlock:progressBlock];

                    break;
                    
                case ZADownloadModelStatePaused:
                    // add blockObject
                    
                    // switch to state Downloading..
                    
                    break;

                case ZADownloadModelStateWaiting:
                    //
                    
                    break;

                case ZADownloadModelStateInterrupted:
                    
                    break;
                default:
                    break;
            }
            return;
        }
        
        // First request, start downloading or waiting.
        NSLog(@"dld: I'm the only one download file: %@",fileName);

        // 1. create downloadtask:
        NSURL *url = [NSURL URLWithString:urlString];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
        NSURLSessionDownloadTask *downloadTask;
        if (backgroundMode) {
            downloadTask = [self.backgroundURLSession downloadTaskWithRequest:request];
        } else {
            downloadTask = [self.forcegroundURLSession downloadTaskWithRequest:request];
        }
        
        // 2. create downloadItem, add to dict.
        destinationUrl = [self getFileUrlWithFileName:fileName directoryName:directoryName];
        ZADownloadItem *downloadItem = [[ZADownloadItem alloc] initWithDownloadTask:downloadTask
                                                                     destinationUrl:destinationUrl
                                                                           progress:progressBlock
                                                                         completion:completionBlock
                                                                            failure:errorBlock
                                                                   isBackgroundMode:backgroundMode
                                                                           priority:priority];
        downloadItem.startDate = [NSDate date];
        downloadItem.fileName = fileName;
        downloadItem.directoryName = directoryName;
        downloadItem.retryCount = retryCount;
        downloadItem.retryInterval = retryInterval;
        [self.downloadItemDict setObject:downloadItem forKey:urlString];
        
        // 3. Start downloading or waiting.
        if ([self canStartADownloadItem]) {
            self.totalDownloadingUrls++;
            [downloadItem start];
        } else {
            [self addToWaitingList: downloadItem];
        }
    });
}

- (void) downloadFileWithURL:(NSString *)urlString
               directoryName:(NSString *)directoryName
        enableBackgroundMode:(BOOL)backgroundMode
                    priority:(ZADownloadModelPriroity)priority
                    progress:(ZADownloadProgressBlock)progressBlock
                  completion:(ZADownloadCompletionBlock)completionBlock
                     failure:(ZADownloadErrorBlock)errorBlock {
    [self downloadFileWithURL:urlString
                directoryName:directoryName
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
//    dispatch_async(_fileDownloaderSerialQueue, ^{
    
        NSString *directoryName = IMAGE_DIRECTORY_NAME;
        
        // check ImageCache:
        UIImage *cachedImage = [DownloadedImageCache.sharededInstance getImageById:urlString];
        // if existed in cache:
        if (cachedImage) {
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
//    });
}

- (void) pauseDowloadingOfUrl:(NSString *)urlString {
    dispatch_async(_fileDownloaderSerialQueue, ^{
        //NSLog(@"dld: start PAUSE");
        ZADownloadItem *downloadItem = [self.downloadItemDict objectForKey:urlString];
        
        // nếu có ít nhất 1 thằng SubItem đang downloading... thì
        [downloadItem pause];
        
        // resume 1 waiting download with highest priority.
        self.totalDownloadingUrls--;
        [self startHighestPriorityZADownloadItem];
        //NSLog(@"dld: finished PAUSE");
    });
}

- (void) resumeDowloadingOfUrl:(NSString *)urlString {
    dispatch_async(_fileDownloaderSerialQueue, ^{
        //NSLog(@"dld: start RESUME");
        ZADownloadItem *downloadItem = [self.downloadItemDict objectForKey:urlString];
        [self resumeDownloadItem:downloadItem];
        //NSLog(@"dld: finished RESUME");
    });
}

- (void) retryDowloadingOfUrl:(NSString *)urlString {
    ZADownloadItem *downloadItem = [self.downloadItemDict objectForKey:urlString];
    [self retryDownloadItem:downloadItem];
}

- (void) cancelDowloadingOfUrl:(NSString *)urlString {
    dispatch_async(_fileDownloaderSerialQueue, ^{
        ZADownloadItem *downloadItem = [self.downloadItemDict objectForKey:urlString];
        
        // decrease total downloading urls:
        if (downloadItem.state == ZADownloadModelStateDowloading) {
            self.totalDownloadingUrls--;
        }
        
        // remove Item out of WaitingLists.
        if (downloadItem.state == ZADownloadModelStateWaiting) {
            [self removeAWaitingDownloadItem:downloadItem];
        }
        
        [downloadItem cancel];
        [self.downloadItemDict removeObjectForKey:urlString];
        
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
    __block ZADownloadItem *downloadItem = nil;
    dispatch_sync(_fileDownloaderSerialQueue, ^{
        downloadItem = [self.downloadItemDict objectForKey:urlString];
    });
    return downloadItem.state;
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
    ZADownloadItem *downloadItem = [self.downloadItemDict objectForKey:urlString];
    
    // cancel old task.
    if (downloadTask.taskIdentifier != downloadItem.downloadTask.taskIdentifier) {
        [downloadTask cancel];
        return;
    }
    

    if (downloadItem.state == ZADownloadModelStateDowloading) {
        for (ZADownloadProgressBlock progressBlock in downloadItem.listProgressBlock) {
            CGFloat progress = (CGFloat)totalBytesWritten/ (CGFloat)totalBytesExpectedToWrite;
            NSUInteger remainingTime = [self remainingTimeForDownload:downloadItem bytesTransferred:totalBytesWritten totalBytesExpectedToWrite:totalBytesExpectedToWrite];
            NSUInteger speed = bytesWritten/1024;
            dispatch_async(dispatch_get_main_queue(), ^{
                progressBlock(progress, speed, remainingTime);
            });
        }
    }
}

// finished downlad file, which is stored as a temporary file in NSURL location.
- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location {
    // get DownloadModel and UrlString from downloadTask.
    NSString *urlString = downloadTask.currentRequest.URL.absoluteString;
    if (!urlString) {
        urlString = downloadTask.originalRequest.URL.absoluteString;
    }
    ZADownloadItem *downloadItem = [self.downloadItemDict objectForKey:urlString];
    
    if (downloadItem && downloadItem.completionBlockDict) {
        // move temporary file to destination:
        NSError *error;

        
        for (NSString *destinationUrlString in downloadItem.completionBlockDict.allKeys) {
            NSLog(@"dld: move to des with name: %@",[destinationUrlString lastPathComponent]);

            [[NSFileManager defaultManager] copyItemAtURL:location toURL:[NSURL URLWithString:destinationUrlString] error:&error];
           
            
            // callback
            ZADownloadCompletionBlock completion = downloadItem.completionBlockDict[destinationUrlString];
            dispatch_async(dispatch_get_main_queue(), ^{
                completion([NSURL URLWithString:destinationUrlString]);
            });
        }
        
        
//        if (!error) {
//            // downloadItem.state = ZADownloadModelStateCompleted;    // không cần trạng thái completed nữa. Xoá luôn.
//            [self.downloadItemDict removeObjectForKey:urlString];
//            _totalDownloadingUrls--;
//            [downloadItem forwardAllCompletionBlockWithDestinationUrl:downloadItem.destinationUrl];
//        } else {
//            NSLog(@"dld: Move file to destination failed.");
//            [downloadItem forwardAllErrorBlockWithError:error];    // move file error.
//            // rồi làm gì nữa????
//            // model trong dict tính sao???
//        }
        
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
    ZADownloadItem *downloadItem = [self.downloadItemDict objectForKey:urlString];
    
    // handle erros:
    switch (error.code) {
        // canceled/paused a task
        case -999:
            return;
            break;
        // No connection.
        case -1009:
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
            downloadItem.state = ZADownloadModelStateInterrupted;
            [downloadItem resetRetryCount];
            if (downloadItem.listErrorBlock) {
                NSError *error = [[NSError alloc] initWithDomain:@"duydl.DownloadManagerDomain" code:DownloadErrorCodeNoConnection userInfo:nil];
                [downloadItem forwardAllErrorBlockWithError:error];
            }
            return;
            break;
        // downloading -> timeout request (loss connection).
        case -1001:
            // handle logic:
            downloadItem.state = ZADownloadModelStateInterrupted;
            if (error.userInfo[NSURLSessionDownloadTaskResumeData]) {
                // save resume
                downloadItem.resumeData = error.userInfo[NSURLSessionDownloadTaskResumeData];
            } else {
                NSError *error = [[NSError alloc] initWithDomain:@"duydl.DownloadManagerDomain" code:DownloadErrorCodeCannotBeResumed userInfo:nil];
                if (downloadItem.listErrorBlock) {
                    [downloadItem forwardAllErrorBlockWithError:error];
                }
                downloadItem.state = ZADownloadModelStateInterrupted;
            }
            
            // retry:
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
            [downloadItem resetRetryCount];
            if (downloadItem.listErrorBlock) {
                NSError *error = [[NSError alloc] initWithDomain:@"duydl.DownloadManagerDomain" code:DownloadErrorCodeTimeoutRequest userInfo:nil];
                [downloadItem forwardAllErrorBlockWithError:error];
            }
            return;
            break;
        default:
            break;
    }
    
    // other errors:
    // [downloadItem forwardAllErrorBlockWithError:error];
    downloadItem.state = ZADownloadModelStateCancelled;
    
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
- (NSUInteger) remainingTimeForDownload: (ZADownloadItem*)downloadItem
                       bytesTransferred: (int64_t)bytesTransferred
              totalBytesExpectedToWrite: (int64_t)totalBytesExpectedToWrite {
    NSTimeInterval timeInterval = [[NSDate date] timeIntervalSinceDate:downloadItem.startDate];
    CGFloat speed = (CGFloat)bytesTransferred / (CGFloat)timeInterval;
    CGFloat remainingBytes = totalBytesExpectedToWrite - bytesTransferred;
    CGFloat remainingTime = remainingBytes / speed;
    return (NSUInteger) remainingTime;
}

- (BOOL) isDowloadingUrl: (NSString*)urlString {
    ZADownloadItem *download = [self.downloadItemDict objectForKey:urlString];
    if (download && download.state == ZADownloadModelStateDowloading) {
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

- (ZADownloadItem*) getHighestPriorityZADownloadModel {
    //NSLog(@"dld: Begin to choose highest priority item");
    //NSLog(@"dld: Before choosing item, HIGH: %lu items, MEDIUM: %lu items, LOW: %lu items",_highPriorityDownloadItems.count,_mediumPriorityDownloadItems.count,_lowPriorityDownloadItems.count);
    ZADownloadItem *highestPriorityDownloadItem = nil;
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
        ZADownloadItem *downloadItem = [self getHighestPriorityZADownloadModel];
        if (downloadItem) {
            downloadItem.state = ZADownloadModelStateDowloading;
            self.totalDownloadingUrls++;
            [downloadItem.downloadTask resume];
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
    for (ZADownloadItem *downloadItem in _downloadItemDict.allValues) {
        if (downloadItem.state == ZADownloadModelStateInterrupted) {
            [self retryDownloadItem:downloadItem];
        }
    }
}

- (void) resumeDownloadItem:(ZADownloadItem*)downloadItem {
    if (downloadItem && downloadItem.resumeData && ((downloadItem.state == ZADownloadModelStatePaused) || (downloadItem.state = ZADownloadModelStateInterrupted))) {
        // recreate downloadtask with resumeData:
        if (downloadItem.isBackgroundMode) {
            downloadItem.downloadTask = [self.backgroundURLSession downloadTaskWithResumeData:downloadItem.resumeData];
        } else {
            downloadItem.downloadTask = [self.forcegroundURLSession downloadTaskWithResumeData:downloadItem.resumeData];
        }

        // start
        [downloadItem start];
        self.totalDownloadingUrls++;
    }
}

- (void) retryDownloadItem:(ZADownloadItem*)downloadItem {
    if (downloadItem.resumeData) {
        [self resumeDownloadItem:downloadItem]; // resume if item has resumeData.
    } else {
        // redownload with new task.
        NSURLRequest *request = downloadItem.downloadTask.originalRequest;
        [downloadItem.downloadTask cancel];
        if (downloadItem.isBackgroundMode) {
            downloadItem.downloadTask = [self.backgroundURLSession downloadTaskWithRequest:request];
        } else {
            downloadItem.downloadTask = [self.forcegroundURLSession downloadTaskWithRequest:request];
        }
        
        // start new downloadtask or waiting.
        if ([self canStartADownloadItem]) {
            [downloadItem start];
            self.totalDownloadingUrls++;
        } else {
            [self addToWaitingList:downloadItem];
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

- (void) removeAWaitingDownloadItem:(ZADownloadItem*)downloadItem {
    switch (downloadItem.priority) {
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

- (void) addToWaitingList:(ZADownloadItem*)downloadItem {
    downloadItem.state = ZADownloadModelStateWaiting;               // waiting for download.
    switch (downloadItem.priority) {
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
