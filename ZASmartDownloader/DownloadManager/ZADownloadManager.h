#import <Foundation/Foundation.h>

// delegate: to notifi about dowloading task status: progress, didfinish,..


@interface ZADownloadManager : NSObject

 + (id) sharedManager;


- (void) downloadFileWithURL: (NSString*)urlString
                    fileName: (NSString*)fileName
             destinationPath: (NSString*)destinationPath
        enableBackgroundMode: (BOOL)backgroundMode
               progressBlock: (void(^)(CGFloat progress))progressCallback
          remainingTimeBlock: (void(^)(NSUInteger seconds))remainingTimeCallback
             completionBlock: (void(^)(BOOL completed))completionCallback;

- (void) pauseDowloadingOfUrl: (NSString*)urlString;

- (void) resumeDowloadingOfUrl: (NSString*)urlString;

@end
