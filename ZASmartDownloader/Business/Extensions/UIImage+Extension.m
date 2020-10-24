//
//  UIImage+Extension.m
//  ZASmartDownloader
//
//  Created by Do Le Duy on 10/23/20.
//  Copyright © 2020 vng. All rights reserved.
//

#import "UIImage+Extension.h"

@implementation UIImage (Extension)

- (NSUInteger)sizeOnMemory {
    return CGImageGetHeight(self.CGImage)*CGImageGetWidth(self.CGImage);;
}

@end
