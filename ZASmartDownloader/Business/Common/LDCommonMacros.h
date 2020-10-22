//
//  LDCommonMacros.h
//  ZASmartDownloader
//
//  Created by Do Le Duy on 10/22/20.
//  Copyright © 2020 vng. All rights reserved.
//

#ifndef LDCommonMacros_h
#define LDCommonMacros_h

/// Syncthesize singleton for a Class
///
#define SYNTHESIZE_SINGLETON_FOR_CLASS(classname)               \
\
+ (classname *)shared##classname {                              \
        static dispatch_once_t pred;                            \
        static classname * shared##classname = nil;             \
        dispatch_once( &pred, ^{                                \
            shared##classname = [[self alloc] init];            \
        });                                                     \
        return shared##classname;                               \
}






#endif /* LDCommonMacros_h */
