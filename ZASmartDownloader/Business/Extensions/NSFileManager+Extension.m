//
//  NSFileManager+Extension.m
//  ZASmartDownloader
//
//  Created by Do Le Duy on 10/22/20.
//  Copyright © 2020 vng. All rights reserved.
//

#import "NSFileManager+Extension.h"
#import "NSURL+Extension.h"
#import "LDCommonMacros.h"

@implementation NSFileManager (Extension)

+ (void)deleteFileName:(NSString *)fileName inDirectoryURL:(NSURL *)directoryURL {
    ifnot (fileName) return;
    ifnot (directoryURL) return;
    
    if ([directoryURL containFileName:fileName] == NO) return;
    
    NSURL *fileURL = [directoryURL appendName:fileName];
    [[NSFileManager defaultManager] removeItemAtURL:fileURL error:nil];
}

+ (void)createDirectoryAtDocumentsIfNeedWithName:(NSString *)directoryName {
    ifnot (directoryName) return;
    if ([self.documentsURL containDirectoryWithName:directoryName]) return;
    
    NSURL *dirURL = [self.documentsURL URLByAppendingPathComponent:directoryName];
    [NSFileManager.defaultManager createDirectoryAtURL:dirURL
                           withIntermediateDirectories:true
                                            attributes:nil
                                                 error:nil];
}

+ (NSURL *)documentsURL {
    NSURL *url = [NSFileManager.defaultManager URLForDirectory:NSDocumentDirectory
                                                      inDomain:NSUserDomainMask
                                             appropriateForURL:nil
                                                        create:false
                                                         error:nil];
    return url;
}

+ (NSURL *)tempURL {
    NSURL *url = [[NSFileManager defaultManager] temporaryDirectory];
    return url;
}

@end
