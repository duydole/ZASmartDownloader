//
//  DownloadItemTableViewCell.h
//  ZASmartDownloader
//
//  Created by Do Le Duy on 10/21/20.
//  Copyright © 2020 vng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ZARequestItem.h"

NS_ASSUME_NONNULL_BEGIN

@interface DownloadItemTableViewCell : UITableViewCell

@property (weak, nonatomic) UILabel *fileName;
@property (weak, nonatomic) UILabel *urlLabel;
@property (weak, nonatomic) UIProgressView *progressView;
@property (weak, nonatomic) UIButton *startButton;
@property (weak, nonatomic) UILabel *downloadedProgressLabel;
@property (weak, nonatomic) UILabel *speedLabel;
@property (weak, nonatomic) UILabel *remainingTimeLabel;
@property (weak, nonatomic) UIButton *cancelButton;
@property (weak, nonatomic) UILabel *priorityLabel;

@property (assign, nonatomic) ZADownloadModelPriroity priority;

@end

NS_ASSUME_NONNULL_END
