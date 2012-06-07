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

// To be called after an image is added or removed
- (void)reconfigureImageContentView {
    scrollView.contentSize = CGSizeMake(scrollView.frame.size.width * [[note images] count], scrollView.frame.size.height);
    pageControl.numberOfPages = [[note images] count];
    
    [self updateTitle];
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
    
    [self reconfigureImageContentView];
    
    // First display of the view, go to the 1st page
    pageControl.currentPage = currentPage;
    
    // pages are created on demand
    // load the visible page
    // load the page on either side to avoid flashes when the user starts scrolling
    //
    [self loadScrollViewWithPage:currentPage - 1];
    [self loadScrollViewWithPage:currentPage];
    [self loadScrollViewWithPage:currentPage + 1];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    
    NSLog(@"ImageGalleryViewController viewDidUnload");
    
    // Release all image views
    for (int i = 0; i < [imageControllers count]; i++) {
        ImageViewController *ivc = [imageControllers objectAtIndex:i];
        if (ivc && (NSNull *)ivc != [NSNull null]) {
            NSLog(@"didReceiveMemoryWarning, removing IVC at %d", i);
            [[ivc view] removeFromSuperview];
            ivc = nil;
            [imageControllers replaceObjectAtIndex:i withObject:[NSNull null]];
        }
    }
    
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
    
    // load the visible page and the page on either side of it (to avoid flashes when the user starts scrolling)
    // TODO: it is slow to load the surrounding pages. Load them in background, maybe via the task queue
    [self loadScrollViewWithPage:currentPage - 1];
    [self loadScrollViewWithPage:currentPage];
    [self loadScrollViewWithPage:currentPage + 1];
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
}

- (IBAction)changePage:(id)sender
{
    currentPage = pageControl.currentPage;
	
    // load the visible page and the page on either side of it (to avoid flashes when the user starts scrolling)
    [self loadScrollViewWithPage:currentPage - 1];
    [self loadScrollViewWithPage:currentPage];
    [self loadScrollViewWithPage:currentPage + 1];
    
	// update the scroll view to the appropriate page
    CGRect frame = scrollView.frame;
    frame.origin.x = frame.size.width * currentPage;
    frame.origin.y = 0;
    [scrollView scrollRectToVisible:frame animated:YES];
    
	// Set the boolean used when scrolls originate from the UIPageControl. See scrollViewDidScroll: above.
    pageControlUsed = YES;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
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
    [pageControl setCurrentPage:[pageControl numberOfPages] - 1];
    [self changePage:nil];
}

- (IBAction)deletePhoto:(id)sender {
    NSLog(@"%@", NSStringFromSelector(_cmd));
}

- (void)didReceiveMemoryWarning {
    NSLog(@"ImageGalleryViewController didReceiveMemoryWarning");
    [super didReceiveMemoryWarning];
    
    // Release all image views except for the currently displayed one
    for (int i = 0; i < [imageControllers count]; i++) {
        if (i == [pageControl currentPage])
            continue;
        
        ImageViewController *ivc = [imageControllers objectAtIndex:i];
        if (ivc && (NSNull *)ivc != [NSNull null]) {
            NSLog(@"  - removing IVC at %d", i);
            [[ivc view] removeFromSuperview];
            ivc = nil;
            [imageControllers replaceObjectAtIndex:i withObject:[NSNull null]];
        }
    }
}

- (void)dealloc {
    NSLog(@"ImageGalleryViewController dealloc");
}

@end
