//
//  ImageGalleryViewController.m
//  MMNotes
//
//  Created by Radek Skokan on 6/6/12.
//  Copyright (c) 2012 radek@skokan.name. All rights reserved.
//

#import "ImageGalleryViewController.h"
#import "MMNAttachment.h"
#import "MMNNote.h"
#import "ImageViewController.h"
#import "MMNDataStore.h"
#import "GAUtils.h"

@interface ImageGalleryViewController ()

@end

@implementation ImageGalleryViewController

- (id)initWithNote:(MMNNote *)n {
    self = [super initWithNibName:@"ImageGalleryViewController" bundle:nil];
    if (self) {
        note = n;
        currentPage = 0;
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    @throw [NSException exceptionWithName:@"Wrong initializer" reason:@"Use initWithNote:" userInfo:nil];
}

- (void)dealloc {
    [self deregisterNotifications];
}

- (void)registerNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(storeUpdated:)
                                                 name:MMNDataStoreUpdateNotification object:nil];
}

- (void)deregisterNotifications {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

// The store has been updated
// TODO there is a bug, the app sometimes crashes somewhere here
- (void)storeUpdated:(NSNotification *)notif {
    [self nullAllImageControllers];
    
    while ([imageControllers count] < [[note images] count]) {
        [imageControllers addObject:[NSNull null]];
    }
    
    [self reconfigureImageContentView];
    // Reload the current and surrounding pages
    [self changePage:nil];
}

// To be called after an image is added or removed
- (void)reconfigureImageContentView {
    int nrOfPages = [[note images] count];
    scrollView.contentSize = CGSizeMake(scrollView.frame.size.width * nrOfPages, scrollView.frame.size.height);
    pageControl.numberOfPages = nrOfPages;
    
    // update the scroll view to the appropriate page
    CGRect frame = scrollView.frame;
    frame.origin.x = frame.size.width * currentPage;
    frame.origin.y = 0;
    [scrollView scrollRectToVisible:frame animated:YES];
    
    [self updateTitle];
    
    // Display help text how to take photos
    if ([pageControl numberOfPages] < 1)
        [takePhotoHelpLabel setHidden:NO];
    else
        [takePhotoHelpLabel setHidden:YES];
}

- (void)updateTitle {
    // Update title
    NSString *title;
    if ([pageControl numberOfPages] < 1) 
        title = @"No Images";
    else
        title = [NSString stringWithFormat:@"%d of %d", [pageControl currentPage] + 1, [pageControl numberOfPages]];
    [[self navigationItem] setTitle:title];
}

- (void)loadScrollViewWithPage:(int)page
{
    if (page < 0)
        return;
    if (page >= [[note images] count])
        return;
    
    // replace the placeholder if necessary
    ImageViewController *controller = [imageControllers objectAtIndex:page];
    if ((NSNull *)controller == [NSNull null])
    {
        controller = [[ImageViewController alloc] initWithImage:[[note orderedImages] objectAtIndex:page]];
        [imageControllers replaceObjectAtIndex:page withObject:controller];
    }
    
    // add the controller's view to the scroll view
    if (controller.view.superview == nil)
    {
        CGRect frame = scrollView.frame;
        frame.origin.x = frame.size.width * page;
        frame.origin.y = 0;
        controller.view.frame = frame;
        [scrollView addSubview:controller.view];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self reconfigureImageContentView];
    
    // pages are created on demand
    // load the visible page
    // load the page on either side to avoid flashes when the user starts scrolling
    //
    [self loadScrollViewWithPage:currentPage - 1];
    [self loadScrollViewWithPage:currentPage];
    [self loadScrollViewWithPage:currentPage + 1];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[GAUtils sharedUtils] trackPageView:[NSString stringWithFormat:@"ImageGallery, nrOfImages=%d", [[note images] count]]];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    NSLog(@"ImageGalleryViewController viewDidLoad");
    // View controllers with the actual images are created lazily.
    // In the meantime, load the array with placeholders which will be replaced on demand.
    imageControllers = [[NSMutableArray alloc] init];
    for (unsigned i = 0; i < [[note images] count]; i++) {
		[imageControllers addObject:[NSNull null]];
    }
    
    // a page is the width of the scroll view
    scrollView.pagingEnabled = YES;
    scrollView.showsHorizontalScrollIndicator = NO;
    scrollView.showsVerticalScrollIndicator = NO;
    scrollView.scrollsToTop = NO;
    scrollView.delegate = self;
    
    // First display of the view, go to the 1st page
    pageControl.currentPage = currentPage;
    
    // TODO: temporarily disabled because of a bug in storeUpdated:
    //    [self registerNotifications];
}

- (void)nullAllImageControllers {
    // Release all image views
    for (int i = 0; i < [imageControllers count]; i++) {
        ImageViewController *ivc = [imageControllers objectAtIndex:i];
        if (ivc && (NSNull *)ivc != [NSNull null]) {
            NSLog(@"Removing IVC at %d", i);
            [[ivc view] removeFromSuperview];
            ivc = nil;
            [imageControllers replaceObjectAtIndex:i withObject:[NSNull null]];
        }
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    
    NSLog(@"ImageGalleryViewController viewDidUnload");
    [self deregisterNotifications];
    [self nullAllImageControllers];
    scrollView = nil;
}

- (void)scrollViewDidScroll:(UIScrollView *)sender
{
    [self releaseNotUsedImages];
    [self updateTitle];
    
    // We don't want a "feedback loop" between the UIPageControl and the scroll delegate in
    // which a scroll event generated from the user hitting the page control triggers updates from
    // the delegate method. We use a boolean to disable the delegate logic when the page control is used.
    if (pageControlUsed)
    {
        // do nothing - the scroll was initiated from the page control, not the user dragging
        return;
    }
	
    // Switch the indicator when more than 50% of the previous/next page is visible
    CGFloat pageWidth = scrollView.frame.size.width;
    currentPage = floor((scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    pageControl.currentPage = currentPage;
    
    [self loadScrollViewWithPage:currentPage];
}

// Releases ImageViewController that are not surrounding the page being currently displayed
- (void)releaseNotUsedImages {
    // image view controllers further from the distance will be released
    static int distanceThreshold = 1;
    
    for (int i = 0; i < [imageControllers count]; i++) {
        int distanceFromCurrentPage = abs(currentPage - i);
        //        NSLog(@"releaseNotUsedImages: currentPage=%d, i=%d, distanceFromCurrentPage=%d", currentPage, i, distanceFromCurrentPage);
        if (distanceFromCurrentPage > distanceThreshold) {
            ImageViewController *ivc = [imageControllers objectAtIndex:i];
            if (ivc && (NSNull *)ivc != [NSNull null]) {
                NSLog(@"releaseNotUsedImages: removing IVC at %d", i);
                [[ivc view] removeFromSuperview];
                ivc = nil;
                [imageControllers replaceObjectAtIndex:i withObject:[NSNull null]];
            }
        }
    }
}

// At the begin of scroll dragging, reset the boolean used when scrolls originate from the UIPageControl
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    pageControlUsed = NO;
}

// At the end of scroll animation, reset the boolean used when scrolls originate from the UIPageControl
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    pageControlUsed = NO;
    
    // pre-load surrounding images
    [self loadScrollViewWithPage:currentPage - 1];
    [self loadScrollViewWithPage:currentPage + 1];
}

- (IBAction)changePage:(id)sender
{
    currentPage = pageControl.currentPage;
	
    // load the visible page and the page on either side of it (to avoid flashes when the user starts scrolling)
    [self loadScrollViewWithPage:currentPage - 1];
    [self loadScrollViewWithPage:currentPage];
    [self loadScrollViewWithPage:currentPage + 1];
    
	// Set the boolean used when scrolls originate from the UIPageControl. See scrollViewDidScroll: above.
    pageControlUsed = YES;
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

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    [self reconfigureImageContentView];
    // Reload the current and surrounding pages
    [self changePage:nil];
}

- (IBAction)takePhoto:(id)sender {
    if ([imagePickerPopover isPopoverVisible]) {
        // On another camera-button click, dismiss the popover if already displayed
        [imagePickerPopover dismissPopoverAnimated:YES];
        imagePickerPopover = nil;
        return;
    }
    
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    [imagePicker setDelegate:self];
    
    // Check if the device has a camera
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        [imagePicker setSourceType:UIImagePickerControllerSourceTypeCamera];
    } else {
        [imagePicker setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
    }
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        imagePickerPopover = [[UIPopoverController alloc] initWithContentViewController:imagePicker];
        [imagePickerPopover setDelegate:self];
        [imagePickerPopover presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    } else {
        [self presentViewController:imagePicker animated:YES completion:nil];
    }
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingImage:(UIImage *)image editingInfo:(NSDictionary *)editingInfo
{
    MMNAttachment *att = [[MMNDataStore sharedStore] createAttachmentWithImage:image];
    [note addAttachmentsObject:att];
    [[MMNDataStore sharedStore] saveChanges];
    [imageControllers addObject:[NSNull null]];
    
    currentPage = [[note images] count] - 1;
    [self reconfigureImageContentView];
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        // on iPhone, dismiss the modally presented image picker
        [self dismissViewControllerAnimated:YES completion:nil];
    } else {
        // on iPad, dismiss the popover
        [imagePickerPopover dismissPopoverAnimated:YES];
        imagePickerPopover = nil;
    }
    
    // Display the just taken (last) image
    [pageControl setCurrentPage:currentPage];
    [self changePage:nil];
}

- (IBAction)deletePhoto:(id)sender {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Delete Image" message:@"Are you sure?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Delete", nil];
    [alert show];
}

// User's reaction to delete the current image.
// Button with index 1 is to delete the image.
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        if ([[note images] count] < 1) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@";-)" message:@"" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
            [alert show];
            return;
        }
        
        // The user confirmed to delete the image
        NSLog(@"The user confirmed to delete the image");
        [[MMNDataStore sharedStore] removeAttachment:[[note orderedImages] objectAtIndex:currentPage]];
        [[MMNDataStore sharedStore] saveChanges];
        
        if (currentPage > [[note images] count] - 1) {
            currentPage = [[note images] count] - 1;
        }
        
        // the order changed, 1 image has been deleted, so clear it all
        [self nullAllImageControllers];
        
        [pageControl setCurrentPage:currentPage];
        [self reconfigureImageContentView];
        [self changePage:nil];
        
    } else {
        NSLog(@"The user canceled deleting the image");
    }
}

- (void)didReceiveMemoryWarning {
    NSLog(@"ImageGalleryViewController didReceiveMemoryWarning");
    [super didReceiveMemoryWarning];
    
    [self nullAllImageControllers];
    
    // load the current page
    [self loadScrollViewWithPage:currentPage];
}

@end
