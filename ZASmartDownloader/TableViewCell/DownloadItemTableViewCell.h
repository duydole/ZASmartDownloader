//
//  DownloadItemTableViewCell.h
//  ZASmartDownloader
//
//  Created by Do Le Duy on 10/21/20.
//  Copyright © 2020 vng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ZARequestItem.h"
#import "DownloadItem.h"

NS_ASSUME_NONNULL_BEGIN

@interface DownloadItemTableViewCell : UITableViewCell

@property (nonatomic, strong) DownloadItem *downloadModel;

@end

NS_ASSUME_NONNULL_END
