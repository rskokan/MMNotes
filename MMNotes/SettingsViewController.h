//
//  SettingsViewController.h
//  MMNotes
//
//  Created by Radek Skokan on 6/18/12.
//  Copyright (c) 2012 radek@skokan.name. All rights reserved.
//
// This controller handles not only UI stuff, but is also responsible for
// all the app settings including payments on App Store.

#import <UIKit/UIKit.h>
#import <StoreKit/StoreKit.h>

@interface SettingsViewController : UIViewController <SKProductsRequestDelegate, SKPaymentTransactionObserver>
{
    
}

@property (weak, nonatomic) IBOutlet UIButton *buyButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UILabel *buyProLabel;

// Indicates whether the user has bought the Pro version
+ (BOOL)isProVersion;

- (IBAction)buyButtonTapped:(id)sender;
- (IBAction)userGuideButtonTapped:(id)sender;
- (IBAction)forumButtonTapped:(id)sender;

@end
