//
//  DownloadedImageCache.h
//  ZASmartDownloader
//
//  Created by CPU11996 on 7/16/19.
//  Copyright © 2019 vng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface LDImageCache : NSObject

+ (instancetype)shared;

- (void)cacheImage:(UIImage *)image byId:(NSString *)imageId;
- (UIImage *)getImageById:(NSString *)imageId;

@end

NS_ASSUME_NONNULL_END
