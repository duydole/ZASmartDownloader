//
//  ZASmartDownloaderTests.m
//  ZASmartDownloaderTests
//
//  Created by CPU11996 on 7/3/19.
//  Copyright © 2019 vng. All rights reserved.
//

// Musics:
#define urlString1 @"https://c1-ex-swe.nixcdn.com/NhacCuaTui945/ConGiGiuaChungTa-MiuLe-5079030.mp"
#define urlString2 @"https://c1-ex-swe.nixcdn.com/NhacCuaTui983/NoiEmMuonToi-HoaproxXesi-5978931.mp3?st=loaeFAJX8DRwVNjYqC9ufA&e=1563004135&download=true"
#define urlString3 @"https://c1-ex-swe.nixcdn.com/NhacCuaTui984/DoTaKhongDoNangCover-TranThanh-6006906.mp3?st=6bTRgAU8a8tzrN2Bs7poBQ&e=1563004120&download=true"
#define urlString4 @"https://c1-ex-swe.nixcdn.com/Sony_Audio57/ThuongEmLaDieuAnhKhongTheNgo-NooPhuocThinh-5827347.mp3?st=BAYLxDK0gG3miFa8_IxzjA&e=1563004206&download=true"

// Images:
#define imageUrl1 @"https://i.ytimg.com/vi/hF_LjTUvP-U/maxresdefault.jpg"
#define imageUrl2 @"http://images2.fanpop.com/images/photos/7800000/Nature-Full-HD-Wallpaper-national-geographic-7822418-1920-1080.jpg"
#define imageUrl3 @"https://i.pinimg.com/originals/76/04/54/7604544a481da491148240ba40bc51b9.jpg"
#define imageUrl4 @"https://images8.alphacoders.com/424/424433.jpg"
#define imageUrl5 @"http://t.wallpaperweb.org/wallpaper/known_places/1920x1080/hdrlakebuilding1920x1080wallpaper6323.jpg"

// Large files:
#define urlFile1 @"https://manuals.info.apple.com/MANUALS/1000/MA1565/en_US/iphone_user_guide.pdf"

#import <XCTest/XCTest.h>
#import "ZADownloadManager.h"

@interface ZASmartDownloaderTests : XCTestCase

@property NSURL *downloadedImageDirectoryUrl;

@end

@implementation ZASmartDownloaderTests

////- (void) testPauseAndReusmeWhenDowloading {
////    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"Test pause and reumse when downloading a url"];
////
////    BOOL backgroundMode = NO;
////    NSString *urlString = urlString1;
////    NSString *fileName = @"FileNameExample.pdf";
////    NSString *directoryName = @"Directory Name Example";
////
////    // delete if existed:
////    [self deleteFileName:fileName inDirectory:directoryName];
////
////    // download async:
////    [ZADownloadManager.sharedInstance downloadFileWithURL:urlString directoryName:directoryName enableBackgroundMode:backgroundMode priority:ZADownloadModelPriroityHigh progress:nil completion:^(NSURL *destinationUrl) {
////        XCTAssert(destinationUrl);
////        [expectation fulfill];
////    } failure:nil];
////
////    sleep(1);
////    [ZADownloadManager.sharedInstance pauseDowloadingOfUrl:urlString];
////    [ZADownloadManager.sharedInstance resumeDowloadingOfUrl:urlString];
////
////    [self waitForExpectations:@[expectation] timeout:30];
////}
//
//// test download 1 image:
//- (void) testDownloadAImage {
//    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"Should download a image successful"];
//    [self deleteFileName:[imageUrl1 lastPathComponent] inDirectoryUrl:_downloadedImageDirectoryUrl];
//
//    [ZADownloadManager.sharedInstance downloadImageWithUrl:imageUrl1 completion:^(UIImage *image, NSURL *destinationPath) {
//        XCTAssertNotNil(image);
//        [expectation fulfill];
//    } failure:nil];
//
//    [self waitForExpectations:@[expectation] timeout:5];
//}
//
//// test download multiple image concurrent:
//- (void) testDownloadMultipleImagesConcurrent {
//    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"Should download multiple images concurrently"];
//    expectation.expectedFulfillmentCount = 3;
//
//    [self deleteFileName:[imageUrl1 lastPathComponent] inDirectoryUrl:_downloadedImageDirectoryUrl];
//    [self deleteFileName:[imageUrl2 lastPathComponent] inDirectoryUrl:_downloadedImageDirectoryUrl];
//    [self deleteFileName:[imageUrl3 lastPathComponent] inDirectoryUrl:_downloadedImageDirectoryUrl];
//
//    [ZADownloadManager.sharedInstance downloadImageWithUrl:imageUrl1 completion:^(UIImage *image, NSURL *destinationPath) {
//        XCTAssertNotNil(image);
//        [expectation fulfill];
//    } failure:nil];
//
//    [ZADownloadManager.sharedInstance downloadImageWithUrl:imageUrl2 completion:^(UIImage *image, NSURL *destinationPath) {
//        XCTAssertNotNil(image);
//        [expectation fulfill];
//    } failure:nil];
//
//    [ZADownloadManager.sharedInstance downloadImageWithUrl:imageUrl3 completion:^(UIImage *image, NSURL *destinationPath) {
//        XCTAssertNotNil(image);
//        [expectation fulfill];
//    } failure:nil];
//
//    [self waitForExpectations:@[expectation] timeout:10];
//}
//
//// test multiple requests download a image concurrent.
//- (void) testMultipleRequestsForDownloadingAImageConcurrently {
//    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"Should download this image 1 time, then forward to all requests"];
//    expectation.expectedFulfillmentCount = 5;
//
//    [self deleteFileName:[imageUrl1 lastPathComponent] inDirectoryUrl:_downloadedImageDirectoryUrl];
//
//    dispatch_apply(5, DISPATCH_APPLY_AUTO, ^(size_t t) {
//        [ZADownloadManager.sharedInstance downloadImageWithUrl:imageUrl1 completion:^(UIImage *image, NSURL *destinationPath) {
//            XCTAssertNotNil(image);
//            [expectation fulfill];
//        } failure:nil];
//    });
//
//    [self waitForExpectations:@[expectation] timeout:5];
//}
//
//// test multiple requests download a image, not concurrent.
//- (void) testMultipleRequestsForDownloadingAImageNotConcurrent {
//    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"Should download this image 1 time, then return with cache"];
//    expectation.expectedFulfillmentCount = 2;
//    NSString *urlString = imageUrl5;
//
//    [self deleteFileName:[urlString lastPathComponent] inDirectoryUrl:_downloadedImageDirectoryUrl];
//
//    // download image first time.
//    // why imageUrl5? do not download imageUrl5 in other testcase, because it will cache this url. So this test will be failed.
//    [ZADownloadManager.sharedInstance downloadImageWithUrl:urlString completion:^(UIImage *image, NSURL *destinationPath) {
//        XCTAssertNotNil(image);
//        XCTAssertNotNil(destinationPath);
//        [expectation fulfill];
//
//        // download again:
//        [ZADownloadManager.sharedInstance downloadImageWithUrl:urlString completion:^(UIImage *image, NSURL *destinationPath) {
//            XCTAssertNotNil(image);
//            XCTAssertNil(destinationPath);              // return image from cache, so destinationPath is nil.
//            [expectation fulfill];
//        } failure:nil];
//    } failure:nil];
//
//    [self waitForExpectations:@[expectation] timeout:10];
//}
//
//// test maxConcurrentDownload
//- (void) testMaxConccurrentDownloadNumber {
//    // set = 2
//
//    // start 3 downloadtask
//
//    // expect status of task 1 -> downloading
//    //                  task 2 -> downloading
//    //                  task 3 -> waiting.
//
//}
//
//# pragma mark - test state of downloadItem logic
//// downloading url -> state must be ZADownloadStateDownloading.
//- (void) testDownloadingStateOfDownloadModel {
//    BOOL backgroundMode = NO;
//    NSString *fileName = @"FileNameExample.mp3";
//    NSString *directoryName = @"Directory Name Example";
//    NSString *urlString = urlFile1;
//
//    // delete if existed:
//    [self deleteFileName:fileName inDirectory:directoryName];
//
//    // start
//    [ZADownloadManager.sharedInstance downloadFileWithURL:urlString directoryName:directoryName enableBackgroundMode:backgroundMode priority:UILayoutPriorityDefaultHigh progress:nil completion:nil failure:nil];
//
//    // check state:
//    XCTAssertEqual([ZADownloadManager.sharedInstance getDownloadStateOfUrl:urlString], ZADownloadItemStateDownloading);
//}
//
//// downloaded url -> state mus be ZADownloadStateCompleted.
//- (void) testPausedStateOfDownloadModel {
////    // setup:
////    BOOL backgroundMode = NO;
////    NSString *fileName = [urlFile1 lastPathComponent];
////    NSString *directoryName = @"Downloaded Files";
////    NSString *urlString = urlFile1;
////
////    // delete if existed:
////    [self deleteFileName:fileName inDirectory:directoryName];
////
////    // start
////    [ZADownloadManager.sharedInstance downloadFileWithURL:urlString directoryName:directoryName enableBackgroundMode:backgroundMode priority:UILayoutPriorityDefaultHigh progress:nil completion:nil failure:nil];
////    NSString *requestId = [ZADownloadManager.sharedInstance downloadFileWithURL:urlString directoryName:directoryName enableBackgroundMode:backgroundMode retryCount:0 retryInterval:0 priority:ZADownloadModelPriroityHigh progress:nil completion:nil failure:nil];
////
////    // pause
////    [ZADownloadManager.sharedInstance pauseDowloadingOfUrl:urlString requestId:requestId];
////
////    // check state
////    XCTAssertEqual(ZADownloadItemStatePaused, [ZADownloadManager.sharedInstance getDownloadStateOfUrl:urlString]);
//}
//
//// test number downloading url.
//- (void) testNumberOfDownladingUrl {
//    XCTAssertEqual(ZADownloadManager.sharedInstance.numberOfDownloadingUrls, 0, @"Number of downloading urls should be 0");
//    [ZADownloadManager.sharedInstance downloadFileWithURL:urlFile1 directoryName:@"directoryName" enableBackgroundMode:NO priority:UILayoutPriorityDefaultHigh progress:nil completion:nil failure:nil];
//
//    XCTAssertEqual(ZADownloadManager.sharedInstance.numberOfDownloadingUrls, 1, @"Number of downloading urls should be 1");
//}
//
//// test download a cancelled download.
//- (void) testReDownloadACancelledDownload {
////    // 0. setup
////    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"Test Redownload a Cancelled Download"];
////    expectation.expectedFulfillmentCount = 1;
////    NSString *urlString = imageUrl1;
////    [self deleteFileName:[urlString lastPathComponent] inDirectoryUrl:_downloadedImageDirectoryUrl];
////
////
////    // 1. download:
////    [ZADownloadManager.sharedInstance downloadImageWithUrl:urlString completion:nil failure:nil];
////
////    // 2. cancel:
////    [ZADownloadManager.sharedInstance cancelDowloadingOfUrl:urlString];
////
////    // 3. download again.
////    [ZADownloadManager.sharedInstance downloadImageWithUrl:urlString completion:^(UIImage *image, NSURL *destinationUrl) {
////        XCTAssert(image);
////        XCTAssert(destinationUrl);
////        [expectation fulfill];
////    } failure:nil];
////
////    [self waitForExpectations:@[expectation] timeout:10];
//}
//
//// test ZADownloadManager with Request:
//- (void) testDownloadWithDownloadRequest {
//    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"Test Redownload a Cancelled Download"];
//    NSString *urlString = imageUrl1;
//
//    // create DownloadRequest:
//    NSURL *destinationUrl = [ZADownloadManager.sharedInstance getDefaultDownloadedFileDirectoryUrl];
//    destinationUrl = [destinationUrl URLByAppendingPathComponent:[urlString lastPathComponent]];
//
//    ZADownloadItem *requestItem = [[ZADownloadItem alloc] initWithUrlString:urlString isBackgroundMode:NO destinationUrl:destinationUrl progress:nil completion:^(NSURL *destinationUrl) {
//        XCTAssert(destinationUrl);
//        [expectation fulfill];
//    } failure:nil];
//
//    // Download by ZADownloadManager.
//    [ZADownloadManager.sharedInstance downloadFileWithRequestItem:requestItem];
//
//    [self waitForExpectations:@[expectation] timeout:3];
//}
//
//# pragma mark - Support methods:
//- (void) deleteFileName:(NSString*)fileName
//            inDirectory:(NSString*)directoryName {
//    NSURL *fileURL;
//    if (directoryName) {
//        fileURL = [[[ZADownloadManager.sharedInstance getDefaultDownloadedFileDirectoryUrl] URLByAppendingPathComponent:directoryName] URLByAppendingPathComponent:fileName];
//    } else {
//        fileURL = [[ZADownloadManager.sharedInstance getDefaultDownloadedFileDirectoryUrl] URLByAppendingPathComponent:fileName];
//    }
//    NSError *error = nil;
//    if ([fileURL checkResourceIsReachableAndReturnError:&error]) {
//        [[NSFileManager defaultManager] removeItemAtURL:fileURL error:&error];
//    }
//}
//
//- (void) deleteFileName:(NSString*)fileName
//         inDirectoryUrl:(NSURL*)directoryUrl {
//    NSURL *fileURL = [directoryUrl URLByAppendingPathComponent:fileName];
//    NSError *error = nil;
//    if ([fileURL checkResourceIsReachableAndReturnError:&error]) {
//        [[NSFileManager defaultManager] removeItemAtURL:fileURL error:&error];
//    }
//}


@end
