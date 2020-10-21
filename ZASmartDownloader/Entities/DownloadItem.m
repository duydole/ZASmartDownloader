//
//  DownloadItem.m
//  ZASmartDownloader
//
//  Created by Do Le Duy on 10/21/20.
//  Copyright © 2020 vng. All rights reserved.
//

#import "DownloadItem.h"

@implementation DownloadItem

- (instancetype) init {
    self = [super init];
    if (self) {
        _downloadFileName = [[NSString alloc] init];
        _downloadUrlString = [[NSString alloc] init];
    }
    return self;
}

@end
