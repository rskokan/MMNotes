//
//  SettingsViewController.m
//  MMNotes
//
//  Created by Radek Skokan on 6/18/12.
//  Copyright (c) 2012 radek@skokan.name. All rights reserved.
//

#import "SettingsViewController.h"

NSString * const MMNotesProIdentifier = @"MMNotesPro";
NSString * const MMNNotesProVersionBoughtPrefKey = @"MMNNotesProVersionBoughtPrefKey";

@interface SettingsViewController ()

@end

@implementation SettingsViewController
{
    
}

@synthesize buyButton;

+ (void)initialize {
    // Store default temporary preferences (in the registration domain) indicating that the Pro version has not been bought yet; used if the app is launched for the 1st time and there are no persistent preferences in the application domain.
    NSDictionary *defaults = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:MMNNotesProVersionBoughtPrefKey];
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
}

+ (BOOL)isProVersion {
    return [[NSUserDefaults standardUserDefaults] boolForKey:MMNNotesProVersionBoughtPrefKey];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        NSString *title = @"Settings";
        [[self navigationItem] setTitle:title];
        [[self tabBarItem] setTitle:title];
        [[self tabBarItem] setImage:[UIImage imageNamed:@"info_tabbar"]];
        
        // Register with App Store
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    }
    return self;
}

- (void)updateBuyButton
{
    if ([SettingsViewController isProVersion]) {
        [[self buyButton] setTitle:@"You have the Pro version" forState:UIControlStateNormal];
        [[self buyButton] setEnabled:NO];
        
    } else {
        if ([SKPaymentQueue canMakePayments]) {
            [[self buyButton] setTitle:@"Buy the Pro version" forState:UIControlStateNormal];
            [[self buyButton] setEnabled:YES];
        } else {
            [[self buyButton] setTitle:@"Purchases are disabled on your device" forState:UIControlStateNormal];
            [[self buyButton] setEnabled:NO];
        }
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.view.backgroundColor = [UIColor groupTableViewBackgroundColor];
    
    [self updateBuyButton];
}

- (void)viewDidUnload
{
    [self setBuyButton:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction)buyButtonTapped:(id)sender {
    [self requestProductData];
}

- (void) requestProductData
{
    SKProductsRequest *request= [[SKProductsRequest alloc] initWithProductIdentifiers:
                                 [NSSet setWithObject:MMNotesProIdentifier]];
    request.delegate = self;
    [request start];
    NSLog(@"Product request for %@ sent", MMNotesProIdentifier);
}

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
    NSArray *products = response.products;
    NSLog(@"Product response for %@ received. Products: %@; invalidProductIdentifiers: %@", MMNotesProIdentifier, products, response.invalidProductIdentifiers);
    
    SKProduct *productToPurchase = nil;
    for (SKProduct *p in products) {
        if ([MMNotesProIdentifier isEqualToString:p.productIdentifier])
            productToPurchase = p;
    }
    
    if (!productToPurchase) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Pro Version Not Found" message:@"The Pro version has not been found in the App Store. Please try later." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alert show];
        return;
    }
    
    // There is only 1 product (the Pro version) and Store Kit asks for purchase confirmation itself
    SKPayment *payment = [SKPayment paymentWithProduct:productToPurchase];
    [[SKPaymentQueue defaultQueue] addPayment:payment];
}

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions {
    for (SKPaymentTransaction *transaction in transactions) {
        switch (transaction.transactionState) {
            case SKPaymentTransactionStatePurchased:
                [self completeTransaction:transaction];
                break;
                
            case SKPaymentTransactionStateFailed:
                [self failedTransaction:transaction];
                break;
                
            case SKPaymentTransactionStateRestored:
                [self restoreTransaction:transaction];
                break;
                
            default:
                break;
        }
    }
}

// The user successfully purchased a product
- (void)completeTransaction:(SKPaymentTransaction *)transaction {
    NSLog(@"Product purchased: %@", transaction.payment.productIdentifier);
    [self updateToProVersion];
    
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
}

// The user successfully purchased a product
- (void)restoreTransaction:(SKPaymentTransaction *)transaction {
    NSLog(@"Product restored: %@", transaction.payment.productIdentifier);
    [self updateToProVersion];
    
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
}

- (void)failedTransaction:(SKPaymentTransaction *) transaction {
    NSString *msg = [NSString stringWithFormat:@"Pro version purchase failed: %@", transaction.error.localizedDescription];
    NSLog(@"%@", msg);
    
    if (transaction.error.code != SKErrorPaymentCancelled) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Purchase Failed" message:msg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
    
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
}

// The user has the Pro version (either just purchased or restored).
// Record this info.
- (void)updateToProVersion {
    NSLog(@"%@", NSStringFromSelector(_cmd));
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:MMNNotesProVersionBoughtPrefKey];
    [self updateBuyButton];
}

@end