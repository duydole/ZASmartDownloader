//
//  DownloadItem.h
//  ZASmartDownloader
//
//  Created by Do Le Duy on 10/21/20.
//  Copyright © 2020 vng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZARequestItem.h"

NS_ASSUME_NONNULL_BEGIN

@interface DownloadItem : NSObject

@property NSString *downloadUrlString;
@property NSString *downloadFileName;
@property ZADownloadModelPriroity priority;

@end

NS_ASSUME_NONNULL_END
