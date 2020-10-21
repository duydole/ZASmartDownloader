//
//  DownloadItemTableViewCell.m
//  ZASmartDownloader
//
//  Created by Do Le Duy on 10/21/20.
//  Copyright © 2020 vng. All rights reserved.
//

#import "DownloadItemTableViewCell.h"
#import "ZADownloadManager.h"

@interface DownloadItemTableViewCell()

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

}

#pragma mark - Events

- (void)tappedStartButton:(id)sender {
    /// Tapped to START/PAUSE/RESUME/RETRY button:

    if ([self.startButton.titleLabel.text isEqualToString:@"START"]) {
        // Tapped to START
        self.cancelButton.enabled = true;
        [self.startButton setTitle:@"PAUSE" forState:UIControlStateNormal];
        NSString *url = self.urlLabel.text;
        //NSString *directoryName = @"Downloaded Files";
        NSUInteger retryInterval = 3;
        NSUInteger retryCount = 3;

        // begin downloading:
        _downloadItem = [ZADownloadManager.sharedInstance downloadFileWithURL:url destinationUrl:nil enableBackgroundMode:NO retryCount:retryCount retryInterval:retryInterval priority:_priority progress:^(CGFloat progress, NSUInteger speed, NSUInteger remainingSeconds) {
            // inprogress:
            // NSLog(@"dld: Downloading file: %@ progress: %f",[self.urlLabel.text lastPathComponent], progress);
            [self.progressView setProgress:progress];
            NSInteger percent = progress*100;
            self.downloadedProgressLabel.text = [[[NSString alloc] initWithFormat:@"%ld",(long)percent] stringByAppendingString:@"%"];
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
    self.downloadedProgressLabel.text = @"0%";
}

#pragma mark - Others

- (void)setPriority:(ZADownloadModelPriroity)priority {
    _priority = priority;
    switch (self.priority) {
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
