//
//  NSFileManager+Extension.m
//  ZASmartDownloader
//
//  Created by Do Le Duy on 10/22/20.
//  Copyright © 2020 vng. All rights reserved.
//

#import "NSFileManager+Extension.h"

@implementation NSFileManager (Extension)

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
