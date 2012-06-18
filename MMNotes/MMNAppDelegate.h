//
//  MMNAppDelegate.h
//  MMNotes
//
//  Created by Radek Skokan on 5/30/12.
//  Copyright (c) 2012 radek@skokan.name. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <iAd/iAd.h>

@protocol BannerViewContainer <NSObject>

- (void)showBannerView:(ADBannerView *)bannerView animated:(BOOL)animated;
- (void)hideBannerView:(ADBannerView *)bannerView animated:(BOOL)animated;

@end

extern NSString * const BannerViewActionWillBegin;
extern NSString * const BannerViewActionDidFinish;

@interface MMNAppDelegate : UIResponder <UIApplicationDelegate, UITabBarControllerDelegate, ADBannerViewDelegate>
{
    // The main tabbar VC (Tags/Notes/Favorites)
    UITabBarController *tabVC;
}

@property (strong, nonatomic) UIWindow *window;

@end
