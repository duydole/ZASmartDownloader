#import "ZADownloadManager.h"
#import "ZADownloadModel.h"

@interface ZADownloadManager() <NSURLSessionDelegate, NSURLSessionDownloadDelegate>

@property NSURLSession *forcegroundSession;
@property NSURLSession *backgroundSession;
@property NSMutableDictionary *dowloadingZADownloadModels;     // a dictionary of downloading file.
@property NSMutableDictionary *waitingZADownloadModels;     // a dictionary of waiting file.

@end

@implementation ZADownloadManager

+ (id) sharedManager {
    static ZADownloadManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] init];
    });
    return sharedManager;
}

- (instancetype) init {
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (void) setup {
    // forceground session with default configuration:
    NSURLSessionConfiguration *defaultConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    self.forcegroundSession = [NSURLSession sessionWithConfiguration:defaultConfig delegate:self delegateQueue:nil];

    // background:
    NSURLSessionConfiguration *backgroundConfig = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:@"backgroundsession"];
    // backgroundConfig.discretionary = true;
    // backgroundConfig.sessionSendsLaunchEvents = true;
    self.backgroundSession = [NSURLSession sessionWithConfiguration:backgroundConfig delegate:self delegateQueue:nil];
    
    // currentZADownloadModels:
    self.dowloadingZADownloadModels = [[NSMutableDictionary alloc] init];
    self.waitingZADownloadModels = [[NSMutableDictionary alloc] init];
}

#pragma mark - External methods:
- (void)downloadFileWithURL:(NSString *)urlString
                   fileName:(NSString *)fileName
            destinationPath:(NSString *)destinationPath
       enableBackgroundMode:(BOOL)backgroundMode
              progressBlock:(void (^)(CGFloat))progressCallback
         remainingTimeBlock:(void (^)(NSUInteger))remainingTimeCallback
            completionBlock:(void (^)(BOOL))completionCallback {
    
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        // 1. create NSURL
        NSURL *url = [NSURL URLWithString:urlString];
        
        // 2. Create request
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        
        // 3. Create task
        NSURLSessionDownloadTask *downloadTask;
        if (backgroundMode) {
            downloadTask = [self.backgroundSession downloadTaskWithRequest:request];
        } else {
            downloadTask = [self.forcegroundSession downloadTaskWithRequest:request];
        }
        
        // 4. Create DownloadModel
        ZADownloadModel *downloadModel = [[ZADownloadModel alloc] initWithDownloadTask:downloadTask
                                                                         progressBlock:progressCallback
                                                                         remainingTime:remainingTimeCallback
                                                                       completionBlock:completionCallback];
        downloadModel.startDate = [NSDate date];
        downloadModel.fileName = fileName;
        downloadModel.destinationPath = destinationPath;
        
        // 5. add to dictionary:
        [self.dowloadingZADownloadModels setObject:downloadModel forKey:urlString];
        
        // 6. Start
        [downloadTask resume];
//    });
}

- (void)pauseDowloadingOfUrl:(NSString *)urlString {
    // 1. get Download Model
    ZADownloadModel *downloadModel = [self.dowloadingZADownloadModels objectForKey:urlString];
    
    // 2. cancle and save resume data.
    [downloadModel.downloadTask cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
        downloadModel.resumeData = resumeData;
        [self.dowloadingZADownloadModels removeObjectForKey:urlString];
        [self.waitingZADownloadModels setObject:downloadModel forKey:urlString];
    }];
}

- (void)resumeDowloadingOfUrl:(NSString *)urlString {
    // 1. get models from waiting download.
    ZADownloadModel *downloadModel = [self.waitingZADownloadModels objectForKey:urlString];
    
    // 2. resume.
    downloadModel.downloadTask = [self.forcegroundSession downloadTaskWithResumeData:downloadModel.resumeData];

    // 3. add to downloading.
    [self.dowloadingZADownloadModels setObject:downloadModel forKey:urlString];
    [self.waitingZADownloadModels removeObjectForKey:urlString];
    
    [downloadModel.downloadTask resume];
}

# pragma mark - NSURLSessionDelegate implementation:
// 1. dowloading state (progress + remaining time) delegate:
- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {

    // 1. get urlString from downloadTask
    // NSString *urlString = downloadTask.originalRequest.URL.absoluteString;
    NSString *urlString = downloadTask.originalRequest.URL.absoluteString;
    if (!urlString) {
        urlString = downloadTask.currentRequest.URL.absoluteString;
    }
    
    // 2. get model from dictionary (memory problem????):
    ZADownloadModel *downloadModel = [self.dowloadingZADownloadModels objectForKey:urlString];
    
    // 3. Call progressBlock:
    if (downloadModel.progressBlock) {
        // calculate progress:
        CGFloat progress = (CGFloat)totalBytesWritten/ (CGFloat)totalBytesExpectedToWrite;
        
        // call main:
        dispatch_async(dispatch_get_main_queue(), ^{
            downloadModel.progressBlock(progress);
        });
    }
    
    // 4. Call remainingTimeBlock
    if (downloadModel.remainingTimeBlock) {
        // calculate remainingTime
        NSUInteger remainingTime = [self remainingTimeForDownload:downloadModel bytesTransferred:totalBytesWritten totalBytesExpectedToWrite:totalBytesExpectedToWrite];
        // callback
        dispatch_async(dispatch_get_main_queue(), ^{
            downloadModel.remainingTimeBlock(remainingTime);
        });
    }
}

// 2. didFinishDownloading URL (location) by downloadTask and Session.
- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location {
    
    // 1. get urlString from downloadTask
    NSString *urlString = downloadTask.currentRequest.URL.absoluteString;
    
    // 2. get model from dictionary (memory problem????):
    ZADownloadModel *downloadModel = [self.dowloadingZADownloadModels objectForKey:urlString];
    
    BOOL success = YES;
    // 3. callback
    if (downloadModel.completionBlock) {
        dispatch_async(dispatch_get_main_queue(), ^{
            downloadModel.completionBlock(success);
        });
    }
}

// 3. download failed -> store ResumeData (apple doc resume and pausing)
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    
}

# pragma mark - Internal methods:
- (NSUInteger) remainingTimeForDownload: (ZADownloadModel*)downloadModel
                       bytesTransferred: (int64_t)bytesTransferred
              totalBytesExpectedToWrite: (int64_t)totalBytesExpectedToWrite {
    NSTimeInterval timeInterval = [[NSDate date] timeIntervalSinceDate:downloadModel.startDate];
    CGFloat speed = (CGFloat)bytesTransferred / (CGFloat)timeInterval;
    CGFloat remainingBytes = totalBytesExpectedToWrite - bytesTransferred;
    CGFloat remainingTime = remainingBytes / speed;
    return (NSUInteger) remainingTime;
}

@end
