//
//  DownloadItemTableViewCell.m
//  ZASmartDownloader
//
//  Created by Do Le Duy on 10/21/20.
//  Copyright © 2020 vng. All rights reserved.
//

#import "DownloadItemTableViewCell.h"
#import "ZADownloadManager.h"
#import "UIView+Extension.h"
#import <UIKit/UIKit.h>

#define SPACING_BETWEEN_LABEL 12
#define STANDARD_PADDING      12
#define SMALL_FONT_SIZE       12
#define LABEL_HEIGHT          20


@interface DownloadItemTableViewCell()

@property (strong, nonatomic) UILabel *fileName;
@property (strong, nonatomic) UILabel *urlLabel;
@property (strong, nonatomic) UIProgressView *progressView;
@property (strong, nonatomic) UIButton *startButton;
@property (strong, nonatomic) UILabel *downloadedProgressLabel;
@property (strong, nonatomic) UILabel *speedLabel;
@property (strong, nonatomic) UILabel *remainingTimeLabel;
@property (strong, nonatomic) UIButton *cancelButton;
@property (strong, nonatomic) UILabel *priorityLabel;

@property (nonatomic, strong) ZARequestItem *downloadItem;

@end

@implementation DownloadItemTableViewCell

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setupSubViews];
    }
    return self;
}

- (void)setupSubViews {
    
}

#pragma mark - Layout Subviews

- (void)layoutSubviews {
    [super layoutSubviews];
    
    ///Name
    [self.fileName sizeToFit];
    self.fileName.frame = CGRectMake(STANDARD_PADDING, STANDARD_PADDING, self.bounds.size.width - STANDARD_PADDING, self.fileName.bounds.size.height);
    
    ///Url
    [self.urlLabel sizeToFit];
    self.urlLabel.left = self.fileName.left;
    self.urlLabel.top = self.fileName.bottom + SPACING_BETWEEN_LABEL;
    self.urlLabel.width = self.fileName.width;
    
    ///Downloaded
    self.downloadedProgressLabel.top = self.urlLabel.bottom + SPACING_BETWEEN_LABEL;
    self.downloadedProgressLabel.left = self.urlLabel.left;
    
    ///RemainTime
    self.remainingTimeLabel.top = self.downloadedProgressLabel.bottom + SPACING_BETWEEN_LABEL;
    self.remainingTimeLabel.left = self.downloadedProgressLabel.left;
    
    ///RemainTime
    [self.priorityLabel sizeToFit];
    self.priorityLabel.top = self.remainingTimeLabel.bottom + SPACING_BETWEEN_LABEL;
    self.priorityLabel.left = self.remainingTimeLabel.left;
    
    ///ProgressView
    self.progressView.top = self.priorityLabel.bottom + SPACING_BETWEEN_LABEL;
    self.progressView.left = self.priorityLabel.left;
    self.progressView.width = self.width - 150;
    
    ///Cancel
    self.cancelButton.right = self.width - STANDARD_PADDING;
    self.cancelButton.bottom = self.height - STANDARD_PADDING;
    
    ///Start
    self.startButton.bottom = self.cancelButton.top - SPACING_BETWEEN_LABEL;
    self.startButton.right = self.cancelButton.right;
}

#pragma mark - Update Model

- (void)setDownloadModel:(DownloadItem *)downloadModel {
    _downloadModel = downloadModel;
    
    [self updatePriorityLabel:_downloadModel.priority];
    self.fileName.text = [downloadModel fileName];
    self.urlLabel.text = [NSString stringWithFormat:@"URL: %@",[downloadModel urlString]];
}

#pragma mark - Events

- (void)tappedStartButton:(id)sender {
    /// Tapped to START/PAUSE/RESUME/RETRY button:

    if ([self.startButton.titleLabel.text isEqualToString:@"START"]) {
        self.cancelButton.enabled = true;
        [self.startButton setTitle:@"PAUSE" forState:UIControlStateNormal];
        NSString *url = self.downloadModel.urlString;
        NSUInteger retryInterval = 3;
        NSUInteger retryCount = 3;

        ///Start download:
        _downloadItem = [ZADownloadManager.sharedInstance downloadFileWithURL:url destinationUrl:nil enableBackgroundMode:NO retryCount:retryCount retryInterval:retryInterval priority:_downloadModel.priority progress:^(CGFloat progress, NSUInteger speed, NSUInteger remainingSeconds) {
            [self.progressView setProgress:progress];
            NSInteger percent = progress*100;
            self.downloadedProgressLabel.text = [[[NSString alloc] initWithFormat:@"DOWNLOADED: %ld",(long)percent] stringByAppendingString:@"%"];
            self.remainingTimeLabel.text = [[NSString alloc] initWithFormat:@"Remaining time: %lu(s)", remainingSeconds];
        } completion:^(NSURL *destinationUrl) {
            dispatch_async(dispatch_get_main_queue(), ^{
                //NSLog(@"dld: on UI, downloaded file: %@",[self.urlLabel.text lastPathComponent]);
                [self.startButton setTitle:@"DOWNLOADED" forState:UIControlStateNormal];
                self.startButton.enabled = false;
                [self.progressView setProgress:1.0];
                self.downloadedProgressLabel.text = @"100%";
            });
        } failure:^(NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self logErrorWithCode:error.code];
            });
        }];
        

    } else if ([self.startButton.titleLabel.text isEqualToString:@"PAUSE"]){
        // Tapped to PAUSE:
        [ZADownloadManager.sharedInstance pauseDownloadingOfRequest:_downloadItem];
        [self.startButton setTitle:@"RESUME" forState:UIControlStateNormal];
        //NSLog(@"dld: tapped PAUSE, now you can tap button RESUME");
        
        
        
    } else if ([self.startButton.titleLabel.text isEqualToString:@"RESUME"]){
        // Tapped to RESUME
        [ZADownloadManager.sharedInstance resumeDownloadingOfRequest:_downloadItem];
        [self.startButton setTitle:@"PAUSE" forState:UIControlStateNormal];
        //NSLog(@"dld: tapped RESUME, now you can tap button PAUSE");
        
        
    } else if ([self.startButton.titleLabel.text isEqualToString:@"RETRY"]) {
        // Tapped to RETRY
        [ZADownloadManager.sharedInstance retryDownloadingOfRequestItem:self.downloadItem];
        [self.startButton setTitle:@"PAUSE" forState:UIControlStateNormal];
    }
}

- (void)cancelDownload:(id)sender {
    // Tapped CANCEL button
    
    [ZADownloadManager.sharedInstance cancelDownloadingOfRequest:self.downloadItem];
    
    [self.startButton setTitle:@"START" forState:UIControlStateNormal];
    self.cancelButton.enabled = false;
    self.startButton.enabled = true;
    [self.progressView setProgress:0];
    self.remainingTimeLabel.text = @"Remaining time: 0(s)";
    self.downloadedProgressLabel.text = @"DOWNLOADED: 0%";
}

#pragma mark - Getter/Setter

- (UILabel *)fileName {
    if (_fileName == nil) {
        _fileName = [UILabel new];
        [self.contentView addSubview:_fileName];
    }
    
    return _fileName;
}

- (UILabel *)urlLabel {
    if (_urlLabel == nil) {
        _urlLabel = [UILabel new];
        _urlLabel.font = [UIFont systemFontOfSize:SMALL_FONT_SIZE];
        [self.contentView addSubview:_urlLabel];
    }
    
    return _urlLabel;
}

- (UILabel *)downloadedProgressLabel {
    if (_downloadedProgressLabel == nil) {
        _downloadedProgressLabel = [UILabel new];
        _downloadedProgressLabel.text = @"DOWNLOADED: 0%";
        _downloadedProgressLabel.width = 200;
        _downloadedProgressLabel.height = LABEL_HEIGHT;
        _downloadedProgressLabel.font = [UIFont systemFontOfSize:SMALL_FONT_SIZE];
        [self.contentView addSubview:_downloadedProgressLabel];
    }
    
    return _downloadedProgressLabel;
}

- (UILabel *)remainingTimeLabel {
    if (_remainingTimeLabel == nil) {
        _remainingTimeLabel = [UILabel new];
        _remainingTimeLabel.width = self.width - 2*STANDARD_PADDING;
        _remainingTimeLabel.height = LABEL_HEIGHT;
        _remainingTimeLabel.text = @"Remaining Time: 0(s)";
        _remainingTimeLabel.font = [UIFont systemFontOfSize:SMALL_FONT_SIZE];
        [self.contentView addSubview:_remainingTimeLabel];
    }
    
    return _remainingTimeLabel;
}

- (UILabel *)priorityLabel {
    if (_priorityLabel == nil) {
        _priorityLabel = [UILabel new];
        _priorityLabel.text = @"Priority: ---";
        _priorityLabel.font = [UIFont systemFontOfSize:SMALL_FONT_SIZE];
        [self.contentView addSubview:_priorityLabel];
    }
    
    return _priorityLabel;
}

- (UIProgressView *)progressView {
    if (_progressView == nil) {
        _progressView = [UIProgressView new];
        
        [self.contentView addSubview:_progressView];
    }
    
    return _progressView;
}

- (UIButton *)startButton {
    if (_startButton == nil) {
        _startButton = [UIButton new];
        _startButton = [UIButton new];
        _startButton.width = 58;
        _startButton.height = 28;
        _startButton.backgroundColor = UIColor.systemBlueColor;
        _startButton.layer.cornerRadius = 5.0;
        _startButton.titleLabel.font = [UIFont systemFontOfSize:13];
        [_startButton setTitle:@"START" forState:UIControlStateNormal];
        [_startButton addTarget:self action:@selector(tappedStartButton:) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:_startButton];
    }
    
    return _startButton;
}

- (UIButton *)cancelButton {
    if (_cancelButton == nil) {
        _cancelButton = [UIButton new];
        _cancelButton.width = 58;
        _cancelButton.height = 28;
        _cancelButton.backgroundColor = UIColor.systemBlueColor;
        _cancelButton.layer.cornerRadius = 5.0  ;
        _cancelButton.titleLabel.font = [UIFont systemFontOfSize:13];
        [_cancelButton setTitle:@"CANCEL" forState:UIControlStateNormal];
        [_cancelButton addTarget:self action:@selector(cancelDownload:) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:_cancelButton];
    }
    
    return _cancelButton;
}

#pragma mark - Others

- (void)updatePriorityLabel:(ZADownloadModelPriroity)priority {
    switch (priority) {
        case ZADownloadModelPriroityLow:
            self.priorityLabel.text = @"Priority: LOW";
            break;
        case ZADownloadModelPriroityMedium:
            self.priorityLabel.text = @"Priority: MEDIUM";
            break;
        case ZADownloadModelPriroityHigh:
            self.priorityLabel.text = @"Priority: HIGH";
            break;
        default:
            break;
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

- (void)showAlertViewWithCode: (DownloadErrorCode) errorCode {
    NSString *alertContent;
    switch (errorCode) {
        case DownloadErrorCodeLossConnection:
            [self.startButton setTitle:@"RETRY" forState:UIControlStateNormal];
            self.startButton.enabled = true;
            alertContent = @"Failed, Loss connection. Please check the network connection.";
            break;
        default:
            alertContent = @"Something wrong";
            break;
    }
    
    UIAlertController *alertView = [UIAlertController alertControllerWithTitle:@"Warning!" message:alertContent preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *alertAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil];
    [alertView addAction:alertAction];
    
    [UIApplication.sharedApplication.keyWindow.rootViewController presentViewController:alertView animated:NO completion:nil];
}

- (void)logErrorWithCode: (DownloadErrorCode) errorCode {
    switch (errorCode) {
        case DownloadErrorCodeLossConnection:
            [self.startButton setTitle:@"RESUME" forState:UIControlStateNormal];
            NSLog(@"dld: Loss connection.");
            break;
        case DownloadErrorCodeNoConnection:
            NSLog(@"dld: No internet connection. Please check the internet connection");
            [self.startButton setTitle:@"RETRY" forState:UIControlStateNormal];
            break;
        case DownloadErrorCodeTimeoutRequest:
            NSLog(@"dld: timeouted waiting connection.");
            [self.startButton setTitle:@"RETRY" forState:UIControlStateNormal];
            break;
        case DownloadErrorCodeOverMaxConcurrentDownloads:
            [self.startButton setTitle:@"RESUME" forState:UIControlStateNormal];
            NSLog(@"dld: Over max concurrent downloads.");
            break;
        default:
            NSLog(@"dld: strange error. Let's debug");
            [self.startButton setTitle:@"RETRY" forState:UIControlStateNormal];
            break;
    }
}

@end
