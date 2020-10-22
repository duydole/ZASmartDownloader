//
//  NSURL+Extension.m
//  ZASmartDownloader
//
//  Created by Do Le Duy on 10/22/20.
//  Copyright © 2020 vng. All rights reserved.
//

#import "NSURL+Extension.h"
#import "LDCommonMacros.h"

@implementation NSURL (Extension)

- (BOOL)containFileName:(NSString *)fileName {
    ifnot (fileName) return NO;
    NSURL *fileURL = [self URLByAppendingPathComponent:fileName];
    BOOL existed = [fileURL checkResourceIsReachableAndReturnError:nil];
    
    return existed;
}

@end
