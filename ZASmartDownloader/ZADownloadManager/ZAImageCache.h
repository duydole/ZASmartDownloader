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

@interface DownloadedImageCache : NSCache

+ (instancetype) sharededInstance;

// store a UIImage with Identifer in Cache.
- (void) storeImage: (UIImage*)image
               byId: (NSString*)imageId;

// get UIImage in cache by Identifier.
- (UIImage*) getImageById: (NSString*)imageId;

@end

NS_ASSUME_NONNULL_END
