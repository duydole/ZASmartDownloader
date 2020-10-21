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

#define CREATE_DOWNLOADITEM(url,name,p) [[DownloadItem alloc] initWithUrlString:url fileName:name priority:p]

@interface DownloadItem : NSObject

- (instancetype)initWithUrlString:(NSString *)urlString
                         fileName:(NSString *)fileName
                         priority:(ZADownloadModelPriroity)priority;

@property (nonatomic, readonly) NSString *urlString;
@property (nonatomic, readonly) NSString *fileName;
@property (nonatomic, readonly) ZADownloadModelPriroity priority;

@end

NS_ASSUME_NONNULL_END
