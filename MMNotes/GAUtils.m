//
//  GAUtils.m
//  MMNotes
//
//  Created by Radek Skokan on 6/27/12.
//  Copyright (c) 2012 radek@skokan.name. All rights reserved.
//

#import "GAUtils.h"

NSString * const kWebPropertyID = @"UA-32944051-2";
const NSInteger kGANDispatchPeriodSec = 30;

@implementation GAUtils

+ (GAUtils *)sharedUtils {
    static dispatch_once_t once;
    static GAUtils *sharedUtils;
    
    dispatch_once(&once, ^{
        sharedUtils = [[super allocWithZone:nil] init];
    });
    
    return sharedUtils;
}

+ (id)allocWithZone:(NSZone *)zone {
    return [self sharedUtils];
}

// Starts the Google Analytics Tracker
// To be called when the app becomes active
- (void)startGATracker {
    [[GANTracker sharedTracker] startTrackerWithAccountID:kWebPropertyID
                                           dispatchPeriod:kGANDispatchPeriodSec
                                                 delegate:self];
    
    NSError *error;
    
    if (![[GANTracker sharedTracker] setCustomVariableAtIndex:1
                                                         name:@"deviceModel"
                                                        value:[[UIDevice currentDevice] model]
                                                    withError:&error]) {
        NSLog(@"Error (GA) setting custom variable deviceModel: %@", [error localizedDescription]);
    }
    
    if (![[GANTracker sharedTracker] setCustomVariableAtIndex:2
                                                         name:@"systemName"
                                                        value:[[UIDevice currentDevice] systemName]
                                                    withError:&error]) {
        NSLog(@"Error (GA) setting custom variable systemName: %@", [error localizedDescription]);
    }
    
    if (![[GANTracker sharedTracker] setCustomVariableAtIndex:3
                                                         name:@"systemVersion"
                                                        value:[[UIDevice currentDevice] systemVersion]
                                                    withError:&error]) {
        NSLog(@"Error (GA) setting custom variable systemVersion: %@", [error localizedDescription]);
    }
    
    // send 100% of the data, no sampling
    [[GANTracker sharedTracker] setSampleRate:100];
}

// Stops the Google Analytics Tracker
// To be called when the app becomes inactive
- (void)stopGATracker {
    [[GANTracker sharedTracker] stopTracker];
}

- (void)trackPageView:(NSString *)pageName {
    NSError *error;
    if (![[GANTracker sharedTracker] trackPageview:pageName
                                         withError:&error]) {
        NSLog(@"Error (GA) tracking page view: %@", [error localizedDescription]);
    }
    
//    BOOL dispatched = [[GANTracker sharedTracker] dispatch];
//    NSLog(@"GA trackPageView request dispatched: %d", dispatched);
}

- (void)trackEventWithCategory:(NSString *)aCategory
                        action:(NSString *) anAction
                         label:(NSString *)aLabel {
    NSError *error;
    if (![[GANTracker sharedTracker] trackEvent:aCategory
                                         action:anAction
                                          label:aLabel
                                          value:0
                                      withError:&error]) {
        NSLog(@"Error (GA) tracking event: %@", [error localizedDescription]);
    }
    
//    BOOL dispatched = [[GANTracker sharedTracker] dispatch];
//    NSLog(@"GA trackEvent request dispatched: %d", dispatched);
}

// Invoked when a hit has been dispatched.
- (void)hitDispatched:(NSString *)hitString {
    //    NSLog(@"%@; hitString=%@", NSStringFromSelector(_cmd), hitString);
}

// Invoked when a dispatch completes. Reports the number of hits
// dispatched and the number of hits that failed to dispatch. Failed
// hits will be retried on next dispatch.
- (void)trackerDispatchDidComplete:(GANTracker *)tracker
                  eventsDispatched:(NSUInteger)hitsDispatched
              eventsFailedDispatch:(NSUInteger)hitsFailedDispatch {
//    NSLog(@"%@; tracker=%@, hitsDispatched=%d, hitsFailedDispatch=%d", NSStringFromSelector(_cmd), tracker, hitsDispatched, hitsFailedDispatch);
}

@end
