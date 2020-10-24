//
//  DownloadedImageCache.m
//  ZASmartDownloader
//
//  Created by CPU11996 on 7/16/19.
//  Copyright © 2019 vng. All rights reserved.
//

#import "ZAImageCache.h"
#import "UIImage+Extension.h"

#define MAX_CACHE_SIZE 10*1024*1024 // 10Mb

@interface LDImageCache()

@property (nonatomic, strong) NSCache *imageCache;
@property (nonatomic, assign) NSInteger maxMemory;

@end

@implementation LDImageCache

+ (instancetype)shared {
    static LDImageCache *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [self new];
    });
    
    return shared;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    _imageCache = [NSCache new];
    _maxMemory = MAX_CACHE_SIZE;
    _imageCache.totalCostLimit = _maxMemory;
}

#pragma mark - Public

- (void)cacheImage:(UIImage *)image byId:(NSString *)imageId {
    if (image && imageId) {
        [_imageCache setObject:image forKey:imageId cost:image.sizeOnMemory];
    }
}

- (UIImage *)getImageById:(NSString *)imageId {
    return [_imageCache objectForKey:imageId];
}

@end
