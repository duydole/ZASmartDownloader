//
//  DownloaderTest.m
//  ZASmartDownloaderTests
//
//  Created by Do Le Duy on 10/26/20.
//  Copyright © 2020 vng. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "ZADownloadManager.h"
#import "NSFileManager+Extension.h"
#import "NSURL+Extension.h"

// Musics:
#define urlMusic1 @"https://c1-ex-swe.nixcdn.com/NhacCuaTui945/ConGiGiuaChungTa-MiuLe-5079030.mp"
#define urlMusic2 @"https://c1-ex-swe.nixcdn.com/NhacCuaTui983/NoiEmMuonToi-HoaproxXesi-5978931.mp3?st=loaeFAJX8DRwVNjYqC9ufA&e=1563004135&download=true"
#define urlMusic3 @"https://c1-ex-swe.nixcdn.com/NhacCuaTui984/DoTaKhongDoNangCover-TranThanh-6006906.mp3?st=6bTRgAU8a8tzrN2Bs7poBQ&e=1563004120&download=true"
#define urlMusic4 @"https://c1-ex-swe.nixcdn.com/Sony_Audio57/ThuongEmLaDieuAnhKhongTheNgo-NooPhuocThinh-5827347.mp3?st=BAYLxDK0gG3miFa8_IxzjA&e=1563004206&download=true"

// Images:
#define imageUrl1 @"https://i.ytimg.com/vi/hF_LjTUvP-U/maxresdefault.jpg"
#define imageUrl2 @"http://images2.fanpop.com/images/photos/7800000/Nature-Full-HD-Wallpaper-national-geographic-7822418-1920-1080.jpg"
#define imageUrl3 @"https://i.pinimg.com/originals/76/04/54/7604544a481da491148240ba40bc51b9.jpg"
#define imageUrl4 @"https://images8.alphacoders.com/424/424433.jpg"
#define imageUrl5 @"http://t.wallpaperweb.org/wallpaper/known_places/1920x1080/hdrlakebuilding1920x1080wallpaper6323.jpg"

// Large files:
#define urlFile1 @"https://manuals.info.apple.com/MANUALS/1000/MA1565/en_US/iphone_user_guide.pdf"

#define TEST_DOWNLOAD_DIR_NAME @"Downloads"
#define TEST_DOWNLOAD_DIR_URL [DOCUMENT_URL appendName:TEST_DOWNLOAD_DIR_NAME]

@interface DownloaderTest : XCTestCase

@end

@implementation DownloaderTest

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

#pragma mark - Validate INPUT

- (void)testDownloadInvalidUrl {
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"Download should failed."];
    NSString *invalidUrl = @"invalidurl.com";
    
    [ZADownloadManager.sharedZADownloadManager downloadFileWithURL:invalidUrl
                                                     directoryName:nil
                                              enableBackgroundMode:NO
                                                          priority:ZADownloadModelPriroityHigh
                                                          progress:nil
                                                        completion:nil
                                                           failure:^(NSError *error) {
        XCTAssertNotNil(error);
        XCTAssertEqual(error.code, DownloadErrorCodeInvalidUrl, "Invalid url");
        [expectation fulfill];
    }];

    /// Đợi đến khi expectation được gọi
    [self waitForExpectations:@[expectation] timeout:5.0];
}

#pragma mark - Foreground Download TestCases

- (void)testDownloadOneUrlOnForeground {
    /// Setup
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"File should be downloaded successful"];
    BOOL backgroundMode = NO;
    NSString *url = urlMusic2;
    NSString *fileName = [url lastPathComponent];
    [NSFileManager deleteFileName:fileName inDirectoryURL:TEST_DOWNLOAD_DIR_URL];

    /// Download
    [ZADownloadManager.sharedZADownloadManager downloadFileWithURL:url
                                                     directoryName:TEST_DOWNLOAD_DIR_NAME
                                              enableBackgroundMode:backgroundMode
                                                          priority:ZADownloadModelPriroityHigh
                                                          progress:nil
                                                        completion:^(NSURL *destinationUrl) {
        XCTAssertNotNil(destinationUrl);
        [expectation fulfill];
    } failure:nil];
    [self waitForExpectations:@[expectation] timeout:10];
}

- (void)testMultipleRequestForDownloadingAUrlOnForeground {
    /// Test download multiple requests
    /// 10 reqeust download 1 URL cùng 1 lúc, nhận được 10 completion
    NSInteger totalOfRequests = 10;
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"Test download 1 url by multiple concurrent requests."];
    expectation.expectedFulfillmentCount = totalOfRequests;
    BOOL backgroundMode = NO;
    NSString *urlString = imageUrl2;
    NSString *fileName = [urlString lastPathComponent];
    NSString *directoryName = TEST_DOWNLOAD_DIR_NAME;
    [NSFileManager deleteFileName:fileName inDirectoryURL:TEST_DOWNLOAD_DIR_URL];
    
    /// Gọi download 1 url 10 lần
    dispatch_apply(totalOfRequests, DISPATCH_APPLY_AUTO, ^(size_t t) {
        NSLog(@"dld: Start download lần %lu",t);
        [ZADownloadManager.sharedZADownloadManager downloadFileWithURL:urlString
                                                         directoryName:directoryName
                                                  enableBackgroundMode:backgroundMode
                                                              priority:ZADownloadModelPriroityHigh
                                                              progress:nil
                                                            completion:^(NSURL *destinationUrl) {
            NSLog(@"dld: Download success in lần: %lu",t);
            XCTAssert(destinationUrl);
            [expectation fulfill];
        } failure:nil];
    });
    
    [self waitForExpectations:@[expectation] timeout:5.0];
}

- (void)testConcurrentDownloadOnForeground {
    /// Test download 2 urls concurrently
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"Test download 2 urls concurrent in background"];
    expectation.expectedFulfillmentCount = 2;
    BOOL backgroundMode = NO;
    NSString *url1 = imageUrl1;
    [NSFileManager deleteFileName:[url1 lastPathComponent] inDirectoryURL:TEST_DOWNLOAD_DIR_URL];
    NSString *url2 = imageUrl2;
    [NSFileManager deleteFileName:[url2 lastPathComponent] inDirectoryURL:TEST_DOWNLOAD_DIR_URL];
    
    [ZADownloadManager.sharedZADownloadManager downloadFileWithURL:url1
                                                     directoryName:TEST_DOWNLOAD_DIR_NAME
                                              enableBackgroundMode:backgroundMode
                                                          priority:ZADownloadModelPriroityHigh
                                                          progress:nil
                                                        completion:^(NSURL *destinationUrl){
        XCTAssert(destinationUrl);
        [expectation fulfill];
    } failure:nil];

    [ZADownloadManager.sharedZADownloadManager downloadFileWithURL:url2
                                                     directoryName:TEST_DOWNLOAD_DIR_NAME
                                              enableBackgroundMode:backgroundMode
                                                          priority:ZADownloadModelPriroityHigh
                                                          progress:nil
                                                        completion:^(NSURL *destinationUrl) {
        XCTAssert(destinationUrl);
        [expectation fulfill];
    } failure:nil];

    [self waitForExpectations:@[expectation] timeout:10];
}

- (void)testDownloadConcurrentAUrlWithTwoDestinationUrl {
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"Test download 1 url (2 request with 2 destinations)"];
    expectation.expectedFulfillmentCount = 2;

    BOOL backgroundMode = NO;
    NSString *urlString = imageUrl2;
    NSString *fileName = [urlString lastPathComponent];
    NSString *directoryName1 = @"Downloaded1";
    NSString *directoryName2 = @"Downloaded2";
    NSURL *destination1 = [DOCUMENT_URL appendName:directoryName1];
    NSURL *destination2 = [DOCUMENT_URL appendName:directoryName2];
    [NSFileManager deleteFileName:fileName inDirectoryURL:destination1];
    [NSFileManager deleteFileName:fileName inDirectoryURL:destination2];
    
    /// download to directory 1
    [ZADownloadManager.sharedZADownloadManager downloadFileWithURL:urlString
                                                     directoryName:directoryName1
                                              enableBackgroundMode:backgroundMode
                                                          priority:ZADownloadModelPriroityHigh
                                                          progress:nil
                                                        completion:^(NSURL *destinationUrl){
        XCTAssert(destinationUrl);
        [expectation fulfill];
    } failure:nil];

    /// download to directory 2
    [ZADownloadManager.sharedZADownloadManager downloadFileWithURL:urlString
                                                     directoryName:directoryName2
                                              enableBackgroundMode:backgroundMode
                                                          priority:ZADownloadModelPriroityHigh
                                                          progress:nil
                                                        completion:^(NSURL *destinationUrl) {
        XCTAssert(destinationUrl);
        [expectation fulfill];
    } failure:nil];

    [self waitForExpectations:@[expectation] timeout:10];
}

#pragma mark - Background Download TestCases

- (void)testMultipleRequestForDownloadingAUrlInBackground {
    NSInteger totalOfRequests = 3;
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"Test download 1 url by multiple concurrent requests."];
    expectation.expectedFulfillmentCount = totalOfRequests;

    BOOL backgroundMode = YES;
    NSString *fileName = [imageUrl1 lastPathComponent];
    NSString *directoryName = @"Downloaded Images";
    [NSFileManager deleteFileName:fileName inDirectoryURL:[DOCUMENT_URL appendName:directoryName]];
    
    dispatch_apply(totalOfRequests, DISPATCH_APPLY_AUTO, ^(size_t t) {
        [ZADownloadManager.sharedZADownloadManager downloadFileWithURL:imageUrl1
                                                         directoryName:directoryName
                                                  enableBackgroundMode:backgroundMode
                                                              priority:ZADownloadModelPriroityHigh
                                                              progress:nil
                                                            completion:^(NSURL *destinationUrl) {
            XCTAssert(destinationUrl);
            [expectation fulfill];
        } failure:nil];
    });

    [self waitForExpectations:@[expectation] timeout:10];
}

- (void)testDownloadConcurrentUrlsInBackground {
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"Test download 2 urls concurrent in background"];
    expectation.expectedFulfillmentCount = 2;

    BOOL backgroundMode = YES;
    NSString *url1 = imageUrl1;
    NSString *url2 = imageUrl2;
    [NSFileManager deleteFileName:[url1 lastPathComponent] inDirectoryURL:TEST_DOWNLOAD_DIR_URL];
    [NSFileManager deleteFileName:[url2 lastPathComponent] inDirectoryURL:TEST_DOWNLOAD_DIR_URL];

    [ZADownloadManager.sharedZADownloadManager downloadFileWithURL:url1
                                                     directoryName:TEST_DOWNLOAD_DIR_NAME
                                              enableBackgroundMode:backgroundMode
                                                          priority:ZADownloadModelPriroityHigh
                                                          progress:nil
                                                        completion:^(NSURL *destinationUrl) {
        XCTAssert(destinationUrl);
        [expectation fulfill];
    } failure:nil];

    [ZADownloadManager.sharedZADownloadManager downloadFileWithURL:url2
                                                     directoryName:TEST_DOWNLOAD_DIR_NAME
                                              enableBackgroundMode:backgroundMode
                                                          priority:ZADownloadModelPriroityHigh
                                                          progress:nil
                                                        completion:^(NSURL *destinationUrl) {
        XCTAssert(destinationUrl);
        [expectation fulfill];
    } failure:nil];
    
    [self waitForExpectations:@[expectation] timeout:10];
}

@end
