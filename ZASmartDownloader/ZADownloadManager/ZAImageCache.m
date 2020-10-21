//
//  DownloadedImageCache.m
//  ZASmartDownloader
//
//  Created by CPU11996 on 7/16/19.
//  Copyright © 2019 vng. All rights reserved.
//

#import "ZAImageCache.h"

@interface DownloadedImageCache()

@property (nonatomic, strong) NSCache *imageCache;
@property (nonatomic, assign) NSInteger maxMemory;

@end

@implementation DownloadedImageCache

+ (instancetype)sharededInstance {
    static DownloadedImageCache *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    _imageCache = [[NSCache alloc] init];
    _maxMemory = 10*1024*1024;                  // 10Mb
    _imageCache.totalCostLimit = _maxMemory;
}

- (void)storeImage:(UIImage *)image
              byId:(NSString *)imageId {
    if (image && imageId) {
        NSUInteger imageSize = CGImageGetHeight(image.CGImage)*CGImageGetWidth(image.CGImage);
        [_imageCache setObject:image forKey:imageId cost:imageSize];
    }
}

- (UIImage *)getImageById:(NSString *)imageId {
    return [_imageCache objectForKey:imageId];
}

@end
