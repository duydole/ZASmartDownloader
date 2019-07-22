//
//  DowloaderTableViewCell.h
//  ZASmartDownloader
//
//  Created by CPU11996 on 7/3/19.
//  Copyright © 2019 vng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ZADownloadManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface DowloaderTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *fileName;
@property (weak, nonatomic) IBOutlet UILabel *urlLabel;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (weak, nonatomic) IBOutlet UIButton *startButton;
@property (weak, nonatomic) IBOutlet UILabel *downloadedProgressLabel;
@property (weak, nonatomic) IBOutlet UILabel *speedLabel;
@property (weak, nonatomic) IBOutlet UILabel *remainingTimeLabel;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UILabel *priorityLabel;
@property (nonatomic) ZADownloadModelPriroity priority;

@end

NS_ASSUME_NONNULL_END
