//
//  ZARequestItem.m
//  ZASmartDownloader
//
//  Created by Duy on 7/24/19.
//  Copyright © 2019 vng. All rights reserved.
//

#import "ZARequestItem.h"
#import "LDCommonMacros.h"
#import "NSFileManager+Extension.h"
#import "NSURL+Extension.h"

@implementation ZARequestItem

- (instancetype)initWithUrlString:(NSString *)urlString
                 isBackgroundMode:(BOOL)isBackgroundMode
                   destinationUrl:(NSURL *)destinationUrl
                         priority:(ZADownloadModelPriroity)priority
                         progress:(ZADownloadProgressBlock)progressBlock
                       completion:(ZADownloadCompletionBlock)completionBlock
                          failure:(ZADownloadErrorBlock)errorBlock {
    self = [super init];
    
    if (self) {
        _requestId = [[NSUUID UUID] UUIDString];
        _urlString = urlString;
        _backgroundMode = isBackgroundMode;
        _priority = priority;
        _destinationUrl = destinationUrl;
        _progressBlock = progressBlock;
        _completionBlock = completionBlock;
        _errorBlock = errorBlock;
        _state = ZADownloadItemStateDownloading;        // ?????
    }
    
    return self;
}

- (NSString *)fileName {
    ifnot (self.urlString) return nil;
    return [self.urlString lastPathComponent];
}

- (BOOL)isExistedOnTempDirectory {
    return [TEMP_URL containFileName:self.fileName];
}

@end
