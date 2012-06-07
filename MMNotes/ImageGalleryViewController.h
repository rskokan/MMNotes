//
//  ImageGalleryViewController.h
//  MMNotes
//
//  Created by Radek Skokan on 6/6/12.
//  Copyright (c) 2012 radek@skokan.name. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MMNNote;

@interface ImageGalleryViewController : UIViewController <UIScrollViewDelegate, UIImagePickerControllerDelegate, UIPopoverControllerDelegate, UINavigationControllerDelegate>
{
    // The note that the image gallery is for.
    MMNNote *note;
    
    NSMutableArray *imageControllers;
    
    BOOL pageControlUsed;
    
    UIPopoverController *imagePickerPopover;
    
    int currentPage;
    
    __weak IBOutlet UIScrollView *scrollView;
    __weak IBOutlet UIPageControl *pageControl;
}

- (id)initWithNote:(MMNNote *)note;

- (IBAction)changePage:(id)sender;
- (IBAction)takePhoto:(id)sender;
- (IBAction)deletePhoto:(id)sender;

@end
