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
#import "MMNDataStore.h"

NSString * const MMNNotesMainTabIndexPrefKey = @"MMNNotesMainTabIndexPrefKey";

@implementation MMNAppDelegate

@synthesize window = _window;

+ (void)initialize {
    // Store default temporary preferences (in the registration domain) for the selected tab index; used if the app is launched for the 1st time and there are no persistent preferences in the application domain.
    // index 1 is for Notes
    NSDictionary *defaults = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:1] forKey:MMNNotesMainTabIndexPrefKey];
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.

    TagsListViewController *tagsListVC = [[TagsListViewController alloc] initWithMode:TagsListViewControllerModeView];
    UINavigationController *tagsNavVC = [[UINavigationController alloc] initWithRootViewController:tagsListVC];
    
    NotesListViewController *notesListVC = [[NotesListViewController alloc] initWithMode:NotesListViewControllerModeAllNotes];
    UINavigationController *notesNavVC = [[UINavigationController alloc] initWithRootViewController:notesListVC];
    
    NotesListViewController *favsListVC = [[NotesListViewController alloc] initWithMode:NotesListViewControllerModeFavoriteNotes];
    UINavigationController *favsNavVC = [[UINavigationController alloc] initWithRootViewController:favsListVC];
    
    NSArray *vcs = [NSArray arrayWithObjects:tagsNavVC, notesNavVC, favsNavVC, nil];
    tabVC = [[UITabBarController alloc] init];
    [tabVC setViewControllers:vcs];
    [[self window] setRootViewController:tabVC];
    
    // Select the lastly active tab
    NSInteger selectedTabIndex = [[NSUserDefaults standardUserDefaults] integerForKey:MMNNotesMainTabIndexPrefKey];
    [tabVC setSelectedIndex:selectedTabIndex];
    
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
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
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    NSLog(@"applicationDidReceiveMemoryWarning:");
}

@end
