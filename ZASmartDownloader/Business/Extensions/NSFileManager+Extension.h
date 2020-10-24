//
//  NSFileManager+Extension.h
//  ZASmartDownloader
//
//  Created by Do Le Duy on 10/22/20.
//  Copyright © 2020 vng. All rights reserved.
//

#import <Foundation/Foundation.h>

#define DOCUMENT_URL    [NSFileManager documentsURL]
#define TEMP_URL        [NSFileManager tempURL]

NS_ASSUME_NONNULL_BEGIN

@interface NSFileManager (Extension)

+ (void)createDirectoryAtDocumentsWithName:(NSString *)directoryName;
+ (NSURL *)documentsURL;
+ (NSURL *)tempURL;

@end

NS_ASSUME_NONNULL_END
