//
//  DownloadItem.m
//  ZASmartDownloader
//
//  Created by Do Le Duy on 10/21/20.
//  Copyright © 2020 vng. All rights reserved.
//

#import "DownloadItem.h"

@implementation DownloadItem

- (instancetype)initWithUrlString:(NSString *)urlString fileName:(NSString *)fileName priority:(ZADownloadModelPriroity)priority {
    self = [super init];
    if (self) {
        _urlString = urlString;
        _fileName = fileName;
        _priority = priority;
    }
    
    return self;
}

@end
