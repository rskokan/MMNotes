//
//  SettingsViewController.m
//  MMNotes
//
//  Created by Radek Skokan on 6/18/12.
//  Copyright (c) 2012 radek@skokan.name. All rights reserved.
//

#import "SettingsViewController.h"
#import "GAUtils.h"

NSString * const MMNotesProIdentifier = @"MMNotesPro";
NSString * const MMNNotesProVersionBoughtPrefKey = @"MMNNotesProVersionBoughtPrefKey";

NSString * const MMNotesVersionPrefKey = @"MMNotesVersionPrefKey";

NSString * const kForumURLString = @"https://groups.google.com/forum/?fromgroups#!forum/mmnotes";
NSString * const kUserGuideURLString = @"http://solucs.com/mmnotes/userguide";

@interface SettingsViewController ()

@end

@implementation SettingsViewController
{
    
}

@synthesize scrollView;
@synthesize backgroundImage;
@synthesize buyButton;
@synthesize activityIndicator;
@synthesize buySectionView;
@synthesize infoSectionView;
@synthesize firstTimeLaunchForCurrentVersion = _firstTimeLaunchForCurrentVersion;

+ (void)initialize {
    // Store default temporary preferences (in the registration domain) indicating that the Pro version has not been bought yet; used if the app is launched for the 1st time and there are no persistent preferences in the application domain.
    NSDictionary *defaults = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:MMNNotesProVersionBoughtPrefKey];
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
}

+ (BOOL)isProVersion {
    return [[NSUserDefaults standardUserDefaults] boolForKey:MMNNotesProVersionBoughtPrefKey];
}

- (BOOL)isFirstTimeLaunchForCurrentVersion {
    NSString *currentVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey];
    NSString *previousVersion = [[NSUserDefaults standardUserDefaults] stringForKey:MMNotesVersionPrefKey];
    
    BOOL res = ![currentVersion isEqualToString:previousVersion];
    NSLog(@"%@: currentVersion=%@, previousVersion=%@ => %d", NSStringFromSelector(_cmd), currentVersion, previousVersion, res);
    
    [[NSUserDefaults standardUserDefaults] setObject:currentVersion forKey:MMNotesVersionPrefKey];
    
    return res;
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

- (void)dealloc {
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
}

- (void)updateBuySectionAnimated:(BOOL)animated
{
    if (self.buySectionView && [SettingsViewController isProVersion]) {
        CGRect newInfoSectionFrame = self.infoSectionView.frame;
        newInfoSectionFrame.origin.y = self.buySectionView.frame.origin.y;
        
        [self.buySectionView removeFromSuperview];
        self.buySectionView = nil;
        
        NSTimeInterval animationDuration = (animated ? 0.25 : 0);
        [UIView animateWithDuration:animationDuration animations:^{
            self.infoSectionView.frame = newInfoSectionFrame;
        }];
        
        [self adjustScrollViewForIphone];
        
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
    
    activityIndicator.hidden = YES;    
    [self updateBuySectionAnimated:NO];
}

- (void)viewDidUnload
{
    [self setBuyButton:nil];
    activityIndicator = nil;
    [self setActivityIndicator:nil];
    [self setBuySectionView:nil];
    [self setInfoSectionView:nil];
    [self setScrollView:nil];
    [self setBackgroundImage:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self oneTimeInitScrollView];
    
    [[GAUtils sharedUtils] trackPageView:@"Settings"];
}

// Weird initial height dimensions of the frame & bounds of the scrollView. I need to re-set it. http://stackoverflow.com/questions/11358442/uiscrollview-height-vs-uiview-height
// Need to be called only once, but when we know dimensions of self.view (so not in viewDidLoad)
- (void)oneTimeInitScrollView {
    static dispatch_once_t once;
    
    dispatch_once(&once, ^{
        self.scrollView.frame = self.view.frame;
        self.scrollView.bounds = self.view.bounds;
        
        [self adjustScrollViewForIphone];
    });
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        return true;
    } else {
        return (interfaceOrientation == UIInterfaceOrientationPortrait)
        || UIInterfaceOrientationIsLandscape(interfaceOrientation);
    }
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    // Make sure that all UI elements can be displayed on iPhones in landscape - scrolling needed
    [self adjustScrollViewForIphoneInUIOrientation:toInterfaceOrientation];
}

- (void)adjustScrollViewForIphone {
    UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    [self adjustScrollViewForIphoneInUIOrientation:interfaceOrientation];
}

- (void)adjustScrollViewForIphoneInUIOrientation:(UIInterfaceOrientation)interfaceOrientation {
//    NSLog(@"\n\n%@ - self.view.frame=%@, self.view.bounds=%@", NSStringFromSelector(_cmd), NSStringFromCGRect(self.view.frame), NSStringFromCGRect(self.view.bounds));
//    NSLog(@"self.scrollView.frame=%@, self.scrollView.bounds=%@", NSStringFromCGRect(self.scrollView.frame), NSStringFromCGRect(self.scrollView.bounds));
    
    // By default there is no need to scroll, everything fits into the screen
    CGRect newContentFrame = self.scrollView.bounds;
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone && ![SettingsViewController isProVersion]) {
        // on iPhones in landscape when also the buySection is displayed, we need to scroll horizontally to see the infoSection
        if (UIInterfaceOrientationIsLandscape(interfaceOrientation)) {
            newContentFrame.size.height *= 1.5;
        }
    }
    
    self.scrollView.contentSize = newContentFrame.size;
    self.backgroundImage.frame = newContentFrame;
}

- (IBAction)buyButtonTapped:(id)sender {
    activityIndicator.hidden = NO;
    [activityIndicator startAnimating];
    
    [self requestProductData];
    
    [[GAUtils sharedUtils] trackEventWithCategory:@"Purchase" action:@"Buy button tapped" label:nil];
}

- (IBAction)restoreButtonTapped:(id)sender {
    activityIndicator.hidden = NO;
    [activityIndicator startAnimating];
    
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
    
    [[GAUtils sharedUtils] trackEventWithCategory:@"Purchase" action:@"Restore button tapped" label:nil];
}

- (IBAction)userGuideButtonTapped:(id)sender {
    NSURL *requestURL = [NSURL URLWithString:kUserGuideURLString];
    [[UIApplication sharedApplication] openURL:requestURL];
    
//    NSURLRequest *forumURLRequest = [NSURLRequest requestWithURL:requestURL cachePolicy:NSURLRequestReloadRevalidatingCacheData timeoutInterval:60];
//    UIWebView *webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
//    [webView loadRequest:forumURLRequest];
//    
//    UIViewController *webVC = [[UIViewController alloc] init];
//    [webVC.view addSubview:webView];
//    [[self navigationController] pushViewController:webVC animated:YES];
}

- (IBAction)forumButtonTapped:(id)sender {
    NSURL *requestURL = [NSURL URLWithString:kForumURLString];
    [[UIApplication sharedApplication] openURL:requestURL];
    
//    NSURLRequest *forumURLRequest = [NSURLRequest requestWithURL:requestURL cachePolicy:NSURLRequestReloadRevalidatingCacheData timeoutInterval:60];
//    UIWebView *webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
//    [webView loadRequest:forumURLRequest];
//    UIViewController *webVC = [[UIViewController alloc] init];
//    [webVC.view addSubview:webView];
//    [[self navigationController] pushViewController:webVC animated:YES];
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
    
    activityIndicator.hidden = YES;
    [activityIndicator stopAnimating];
    
    SKProduct *productToPurchase = nil;
    for (SKProduct *p in products) {
        if ([MMNotesProIdentifier isEqualToString:p.productIdentifier])
            productToPurchase = p;
    }
    
    if (!productToPurchase) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Pro Version Not Found" message:@"The Pro version has not been found in the App Store. Please try later." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alert show];
        [[GAUtils sharedUtils] trackEventWithCategory:@"Purchase" action:@"Product not found" label:MMNotesProIdentifier];
        return;
    }
    
    // There is only 1 product (the Pro version) and Store Kit asks for purchase confirmation itself
    SKPayment *payment = [SKPayment paymentWithProduct:productToPurchase];
    NSLog(@"Adding payment to the queue: productIdentifier=%@, quantity=%d", payment.productIdentifier, payment.quantity);
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
    [self upgradeToProVersion];
    
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
    
    [[GAUtils sharedUtils] trackEventWithCategory:@"Purchase" action:@"Purchase finished" label:nil];
}

// The user successfully restored the previously purchased product
- (void)restoreTransaction:(SKPaymentTransaction *)transaction {
    NSLog(@"Product restored: %@", transaction.payment.productIdentifier);
    [self upgradeToProVersion];
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
    
    activityIndicator.hidden = YES;
    [activityIndicator stopAnimating];
    
    [[GAUtils sharedUtils] trackEventWithCategory:@"Purchase" action:@"Restore finished" label:nil];
}

- (void)failedTransaction:(SKPaymentTransaction *) transaction {
    NSString *msg = [NSString stringWithFormat:@"Pro version purchase/restore failed: %@", transaction.error];
    NSLog(@"%@", msg);
    
    if (transaction.error.code != SKErrorPaymentCancelled) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Purchase/Restore Failed" message:msg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
    
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
    
    [[GAUtils sharedUtils] trackEventWithCategory:@"Purchase" action:@"Purchase/Restore failed" label:transaction.error.description];
}

- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue {
    // This method just informs that the restore transaction has finished.
    // It does not mean that any products have been restored. So just stop the animation but do nut upgrade!
    NSLog(@"%@", NSStringFromSelector(_cmd));
    
    activityIndicator.hidden = YES;
    [activityIndicator stopAnimating];
}

- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Restore failed" message:error.localizedDescription delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
    
    NSLog(@"%@, error: %@", NSStringFromSelector(_cmd), error);
    [[GAUtils sharedUtils] trackEventWithCategory:@"Purchase" action:@"Restore failed" label:error.description];
    
    activityIndicator.hidden = YES;
    [activityIndicator stopAnimating];
}

// The user has the Pro version (either just purchased or restored).
// Record this info.
- (void)upgradeToProVersion {
    NSLog(@"%@", NSStringFromSelector(_cmd));
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:MMNNotesProVersionBoughtPrefKey];
    [self updateBuySectionAnimated:YES];
}

@end
