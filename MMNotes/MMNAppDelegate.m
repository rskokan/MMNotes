//
//  MMNAppDelegate.m
//  MMNotes
//
//  Created by Radek Skokan on 5/30/12.
//  Copyright (c) 2012 radek@skokan.name. All rights reserved.
//

#import "MMNAppDelegate.h"
#import "NotesListViewController.h"
#import "TagsListViewController.h"
#import "SettingsViewController.h"
#import "MMNDataStore.h"
#import "GAUtils.h"

NSString * const MMNNotesMainTabIndexPrefKey = @"MMNNotesMainTabIndexPrefKey";

NSString * const BannerViewActionWillBegin = @"BannerViewActionWillBegin";
NSString * const BannerViewActionDidFinish = @"BannerViewActionDidFinish";

@implementation MMNAppDelegate
{
    UIViewController<BannerViewContainer> *_currentIAdTabController;
    ADBannerView *_bannerView;
}

@synthesize window = _window;

+ (void)initialize {
    // Store default temporary preferences (in the registration domain) for the selected tab index; used if the app is launched for the 1st time and there are no persistent preferences in the application domain.
    // index 1 is for Notes
    NSDictionary *defaults = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:1] forKey:MMNNotesMainTabIndexPrefKey];
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    self.window = [[UIWindow alloc] initWithFrame:screenBounds];
    self.window.backgroundColor = [UIColor whiteColor];
    // Override point for customization after application launch.
    
    TagsListViewController *tagsListVC = [[TagsListViewController alloc] initWithMode:TagsListViewControllerModeView];
    UINavigationController *tagsNavVC = [[UINavigationController alloc] initWithRootViewController:tagsListVC];
    
    NotesListViewController *notesListVC = [[NotesListViewController alloc] initWithMode:NotesListViewControllerModeAllNotes];
    UINavigationController *notesNavVC = [[UINavigationController alloc] initWithRootViewController:notesListVC];
    
    NotesListViewController *favsListVC = [[NotesListViewController alloc] initWithMode:NotesListViewControllerModeFavoriteNotes];
    UINavigationController *favsNavVC = [[UINavigationController alloc] initWithRootViewController:favsListVC];
    
    SettingsViewController *settingsVC = [[SettingsViewController alloc] init];
    
    NSArray *vcs = [NSArray arrayWithObjects:tagsNavVC, notesNavVC, favsNavVC, settingsVC, nil];
    tabVC = [[UITabBarController alloc] init];
    [tabVC setViewControllers:vcs];
    [tabVC setDelegate:self];
    [[self window] setRootViewController:tabVC];
    
    // Select the lastly active tab
    NSInteger selectedTabIndex = [[NSUserDefaults standardUserDefaults] integerForKey:MMNNotesMainTabIndexPrefKey];
    [tabVC setSelectedIndex:selectedTabIndex];
    
    UINavigationController *selectedNavVC = (UINavigationController *)tabVC.selectedViewController;
    
    // The ADBannerView will fix up the given size, we just want to ensure it is created at a location off the bottom of the screen.
    // This ensures that the first animation doesn't come in from the top of the screen.
    if (![SettingsViewController isProVersion]) {
        _bannerView = [[ADBannerView alloc] initWithFrame:CGRectMake(0.0, screenBounds.size.height, 0.0, 0.0)];
        _bannerView.delegate = self;
        
        // Don't display the ad banner in Settings
        if (![selectedNavVC isKindOfClass:[SettingsViewController class]]) {
            _currentIAdTabController = (UIViewController<BannerViewContainer> *) [selectedNavVC.viewControllers objectAtIndex:0];
        }
    }
    
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    
    NSLog(@"%@", NSStringFromSelector(_cmd));
    
    [[GAUtils sharedUtils] stopGATracker];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
    if (![[MMNDataStore sharedStore] saveChanges])
        NSLog(@"Error saving app data");
    
    // Save the active tab (Tags/Notes/Favorites)
    [[NSUserDefaults standardUserDefaults] setInteger:[tabVC selectedIndex] forKey:MMNNotesMainTabIndexPrefKey];
    //    [tabVC selectedIndex]
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    
    NSLog(@"%@", NSStringFromSelector(_cmd));
    
    [[GAUtils sharedUtils] startGATracker];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    NSLog(@"applicationDidReceiveMemoryWarning:");
}

- (void)bannerViewDidLoadAd:(ADBannerView *)banner
{
    [_currentIAdTabController showBannerView:_bannerView animated:YES];
}

- (void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error
{
    [_currentIAdTabController hideBannerView:_bannerView animated:YES];
    NSLog(@"Error loading iAd ads: %@", [error localizedDescription]);
}

- (BOOL)bannerViewActionShouldBegin:(ADBannerView *)banner willLeaveApplication:(BOOL)willLeave
{
    [[NSNotificationCenter defaultCenter] postNotificationName:BannerViewActionWillBegin object:self];
    return YES;
}

- (void)bannerViewActionDidFinish:(ADBannerView *)banner
{
    [[NSNotificationCenter defaultCenter] postNotificationName:BannerViewActionDidFinish object:self];
}

- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController
{
    if ([SettingsViewController isProVersion]) {
        if (_currentIAdTabController) {
            [_currentIAdTabController hideBannerView:_bannerView animated:NO];
            _currentIAdTabController = nil;
            _bannerView = nil;
        }
        
    } else {
        // Don't display the ad banner in Settings
        if ([viewController isKindOfClass:[SettingsViewController class]]) {
            return;
        }
        
        // viewController in the tab is a UINavigationController. We are interrested in its root [0] element
        UINavigationController *selectedNavVC = (UINavigationController *)viewController;
        UIViewController<BannerViewContainer> *vcInTab = (UIViewController<BannerViewContainer> *) [selectedNavVC.viewControllers objectAtIndex:0];
        
        if (_currentIAdTabController == vcInTab) {
            return;
        }
        
        if (_bannerView.bannerLoaded) {
            [_currentIAdTabController hideBannerView:_bannerView animated:NO];
            [vcInTab showBannerView:_bannerView animated:YES];
        }
        _currentIAdTabController = vcInTab;
    }
}

@end
