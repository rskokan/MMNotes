//
//  GAUtils.h
//  MMNotes
//
//  Created by Radek Skokan on 6/27/12.
//  Copyright (c) 2012 radek@skokan.name. All rights reserved.
//
// Utility methods for Google Analytics

#import <UIKit/UIKit.h>
#import "GANTracker.h"

@interface GAUtils : NSObject <GANTrackerDelegate>

// Returns the singleton instance
+(GAUtils *)sharedUtils;

// Starts the Google Analytics Tracker
// To be called when the app becomes active
- (void)startGATracker;

// Stops the Google Analytics Tracker
// To be called when the app becomes inactive
- (void)stopGATracker;

- (void)trackPageView:(NSString *)pageName;

- (void)trackEventWithCategory:(NSString *)aCategory
                        action:(NSString *) anAction
                         label:(NSString *)aLabel;

@end
