//
//  NSURL+Extension.h
//  ZASmartDownloader
//
//  Created by Do Le Duy on 10/22/20.
//  Copyright © 2020 vng. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSURL (Extension)

- (BOOL)containFileName:(NSString *)fileName;

@end

NS_ASSUME_NONNULL_END
