//
//  ImageViewController.m
//  MMNotes
//
//  Created by Radek Skokan on 6/6/12.
//  Copyright (c) 2012 radek@skokan.name. All rights reserved.
//

#import "ImageViewController.h"
#import "MMNAttachment.h"

@interface ImageViewController ()

@end

@implementation ImageViewController

@synthesize imageAttachment = _imageAttachment;

// The designated initializer.
- (id)initWithImage:(MMNAttachment *)ia {
    if ([ia attachmentType] != MMNAttachmentTypeImage) {
        @throw [NSException exceptionWithName:@"Wrong attachment type" reason:[NSString stringWithFormat: @"The type of the attachment %@ is not MMNAttachmentTypeImage", ia] userInfo:nil];
        return nil;
    }
    
    self = [super initWithNibName:@"ImageViewController" bundle:nil];
    if (self) {
        _imageAttachment = ia;
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    @throw [NSException exceptionWithName:@"Wrong initializer" reason:@"Use initWithImage:" userInfo:nil];
}

- (NSString *)formatDateTaken:(NSDate *)date {
    static NSDateFormatter *df = nil;
    
    if (!df) {
        df = [[NSDateFormatter alloc] init];
        [df setDateStyle:NSDateFormatterMediumStyle];
        [df setTimeStyle:NSDateFormatterMediumStyle];
    }
    
    return [df stringFromDate:date];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [imageView setImage:[UIImage imageWithData:[[self imageAttachment] data]]];
    [dateLabel setText:[self formatDateTaken:[[self imageAttachment ]dateModified]]];
}

- (void)viewDidUnload
{
    NSLog(@"ImageViewController viewDidUnload:  %@", [self imageAttachment]);
    imageView = nil;
    dateLabel = nil;
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
//    || UIInterfaceOrientationIsLandscape(interfaceOrientation);
}

- (void)didReceiveMemoryWarning {
    NSLog(@"ImageViewController didReceiveMemoryWarning");
    imageView = nil;
    dateLabel = nil;
}

- (void)dealloc {
    NSLog(@"ImageViewController dealloc");
    imageView = nil;
    dateLabel = nil;
}

@end
