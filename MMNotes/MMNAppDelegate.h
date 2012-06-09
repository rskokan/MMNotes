//
//  MMNAppDelegate.h
//  MMNotes
//
//  Created by Radek Skokan on 5/30/12.
//  Copyright (c) 2012 radek@skokan.name. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MMNAppDelegate : UIResponder <UIApplicationDelegate>
{
    // The main tabbar VC (Tags/Notes/Favorites)
    UITabBarController *tabVC;
}

@property (strong, nonatomic) UIWindow *window;

@end
