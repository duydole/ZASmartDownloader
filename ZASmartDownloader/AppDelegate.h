//
//  AppDelegate.h
//  ZASmartDownloader
//
//  Created by CPU11996 on 7/3/19.
//  Copyright © 2019 vng. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property void(^backgroundSessionCompleteHandler)(void);

@end


