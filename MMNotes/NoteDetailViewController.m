//
//  NoteDetailViewController.m
//  MMNotes
//
//  Created by Radek Skokan on 5/30/12.
//  Copyright (c) 2012 radek@skokan.name. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "NoteDetailViewController.h"
#import "MMNDataStore.h"
#import "MMNNote.h"
#import "TagsListViewController.h"
#import "ImageGalleryViewController.h"

@interface NoteDetailViewController ()

@end

@implementation NoteDetailViewController

@synthesize note = _note, dismissBlock = _dismissBlock, isNew = _isNew;

- (id)initForNewNote:(BOOL)new {
    self = [super initWithNibName:@"NoteDetailViewController" bundle:nil];
    if (self) {
        _isNew = new;
        [self registerForKeyboardNotifications];
        
        // Not at the top level, hide the main tabbar
        [self setHidesBottomBarWhenPushed:YES];
    }
    
    return self;
}

- (id)init {
    @throw [NSException exceptionWithName:@"Wrong initializer" reason:@"Use initForNewNote:" userInfo:nil];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    @throw [NSException exceptionWithName:@"Wrong initializer" reason:@"Use initForNewNote:" userInfo:nil];
    return nil;
}

- (void)toggleFavorite:(id)sender {
    // Convert the NSNumber value (Core Data) to BOOL
    BOOL isFavorite = [[[self note] isFavorite] boolValue];
    
    if (isFavorite) {
        [[self note] setIsFavorite:[NSNumber numberWithBool:NO]];
    } else {
        [[self note] setIsFavorite:[NSNumber numberWithBool:YES]];
    }
    
    [self updateFavoriteItemStatus];
}

// update the indication (highlighted star) whether the note is a favorite
- (void)updateFavoriteItemStatus {
    if ([[[self note] isFavorite] boolValue]) {
        [favoriteItem setTintColor:[UIColor yellowColor]];
    } else {
        [favoriteItem setTintColor:nil];
    }
}

// update the indication (highlighted camea) whether the note has any images
- (void)updatePhotoItemStatus {
    if ([[[self note] images] count] > 0) {
        [photoItem setTintColor:[UIColor yellowColor]];
    } else {
        [photoItem setTintColor:nil];
    }
}

- (void)save:(id)sender {
    [[self presentingViewController] dismissViewControllerAnimated:YES completion:[self dismissBlock]];
}

// The Cancel button has been pressed
- (void)cancel:(id)sender {
    // Confirmation if the note has some contents
    [[self note] setTitle:[titleField text]];
    [[self note] setBody:[bodyField text]];
    
    if ([[self note] isEmpty]) {
        // Discard the new note only when it is empty
        [[MMNDataStore sharedStore] removeNote:[self note]];
        [[self presentingViewController] dismissViewControllerAnimated:YES completion:[self dismissBlock]];
    } else {
        // Otherwise ask for confirmation
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Discard Note" message:@"The note is not empty. Do you want to discard it?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Discard", nil];
        [alert show];
    }
}

// The trash toolbar button has been tapped. Ask the user to confirm deletion.
- (void)askToDelete:(id)sender {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Delete Note" message:@"Are you sure?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Delete", nil];
    [alert show];
}

// User's reaction to cancel a new nonempty or delete an existing note.
// Button with index 1 is to delete the note.
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        // The user confirmed to discard / delete the note
        NSLog(@"The user confirmed to delete an existing / discard the new not empty note");
        [[MMNDataStore sharedStore] removeNote:[self note]];
        if ([self isNew]) {
            [[self presentingViewController] dismissViewControllerAnimated:YES completion:[self dismissBlock]];
        } else {
            [[self navigationController] popViewControllerAnimated:YES];
        }
    } else {
        NSLog(@"The user canceled deleting / discarding the note");
    }
}

- (void)setNote:(MMNNote *)n {
    _note = n;
    if (![self isNew])
        [[self navigationItem] setTitle:[[self note] displayText]];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Show the bottom toolbar
    [[self navigationController] setToolbarHidden:NO animated:YES];
    
    [titleField setText:[[self note] title]];
    [bodyField setText:[[self note] body]];
    
    [tagsButton setTitle:[[self note] orderedTagsString] forState:UIControlStateNormal];
    
    [self updateFavoriteItemStatus];
    [self updatePhotoItemStatus];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    // Hide the bottom toolbar
    [[self navigationController] setToolbarHidden:YES animated:YES];
    
    // Clear first responder (hide keyboard)
    [[self view] endEditing:YES];
    
    [[self note] setTitle:[titleField text]];
    [[self note] setBody:[bodyField text]];
    [[MMNDataStore sharedStore] saveChanges];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    [[bodyField layer] setBorderWidth:1];
    [[bodyField layer] setBorderColor:[[UIColor grayColor] CGColor]];
    
    if ([self isNew]) {
        UIBarButtonItem *doneItem = [[UIBarButtonItem alloc]
                                     initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                     target:self
                                     action:@selector(save:)];
        [[self navigationItem] setRightBarButtonItem:doneItem];
        
        UIBarButtonItem *cancelItem = [[UIBarButtonItem alloc]
                                       initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                       target:self
                                       action:@selector(cancel:)];
        [[self navigationItem] setLeftBarButtonItem:cancelItem];
    }
    
    // Standard bottom toolbar items
    favoriteItem = [[UIBarButtonItem alloc]
                    initWithImage:[UIImage imageNamed:@"star_toolbar"]
                    style:UIBarButtonItemStylePlain
                    target:self
                    action:@selector(toggleFavorite:)];
    photoItem = [[UIBarButtonItem alloc]
                 initWithBarButtonSystemItem:UIBarButtonSystemItemCamera
                 target:self
                 action:@selector(showPhotos:)];
    //    audioItem = [[UIBarButtonItem alloc]
    //                 initWithImage:[UIImage imageNamed:@"mic_toolbar"]
    //                 style:UIBarButtonItemStylePlain
    //                 target:self
    //                 action:@selector(showAudios:)];
    UIBarButtonItem *trashItem = [[UIBarButtonItem alloc]
                                  initWithBarButtonSystemItem:UIBarButtonSystemItemTrash
                                  target:self
                                  action:@selector(askToDelete:)];
    UIBarButtonItem *flexiSpace = [[UIBarButtonItem alloc]
                                   initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    //    [self setToolbarItems:[NSArray arrayWithObjects:favoriteItem, flexiSpace, photoItem, flexiSpace, audioItem, flexiSpace, trashItem, nil] animated:YES];
    [self setToolbarItems:[NSArray arrayWithObjects:favoriteItem, flexiSpace, photoItem, flexiSpace, trashItem, nil] animated:YES];
    
    originalBodyFieldHeight = [bodyField frame].size.height;
}

- (void)viewDidUnload
{
    titleField = nil;
    bodyField = nil;
    tagsButton = nil;
//    scrollView = nil;
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait)
    || UIInterfaceOrientationIsLandscape(interfaceOrientation);
}

- (IBAction)showTagsPicker:(id)sender {
    TagsListViewController *tagsListVC = [[TagsListViewController alloc] initWithMode:TagsListViewControllerModeSelect];
    [tagsListVC setNote:[self note]];
    [[self navigationController] pushViewController:tagsListVC animated:YES];
}

- (IBAction)backgroundTapped:(id)sender {
    [[self view] endEditing:YES];
}

- (IBAction)titleFieldChanged:(id)sender {
    [[self navigationItem] setTitle:[titleField text]];
}

// Hide keyboard when return is pressed
// TODO: check; we also have more text fields
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

// The camera button has been clicked, show the photo gallery
- (void)showPhotos:(id)sender {
    ImageGalleryViewController *igvc = [[ImageGalleryViewController alloc] initWithNote:[self note]];
    [[self navigationController] pushViewController:igvc animated:YES];
}

- (void)registerForKeyboardNotifications {
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

// Called when the UIKeyboardDidShowNotification is sent.
- (void)keyboardWasShown:(NSNotification *)notif {
    NSDictionary *info = [notif userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    ///
    
    // TODO: improve, don't shrink the TextField, use the ScrollView instead (didn't work wel for me, needs some time...)
    NSLog(@"Before: originalBodyFieldHeight=%f, kbSize.height=%f, bodyField.frame.size.height=%f", originalBodyFieldHeight, kbSize.height, bodyField.frame.size.height);
    measuredBodyFieldHeight = bodyField.frame.size.height;
    
    CGRect bodyFieldFrame = [bodyField frame];
    bodyFieldFrame.size.height = originalBodyFieldHeight - kbSize.height - 25; // it's strange, bodyFieldFrame.size.height != the original height here
    // Probably because in the design view in IB, I dont have the top and button bars!!!
    [bodyField setFrame:bodyFieldFrame];
    
    NSLog(@"After: bodyField.frame.size.height=%f", bodyField.frame.size.height);
    
    ///
//    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height, 0.0);
//    scrollView.contentInset = contentInsets;
//    scrollView.scrollIndicatorInsets = contentInsets;
    
    // If active text field is hidden by keyboard, scroll it so it's visible
    // Your application might not need or want this behavior.
//    CGRect aRect = self.view.frame;
//    aRect.size.height -= kbSize.height;
//    if (!CGRectContainsPoint(aRect, activeField.frame.origin) ) {
//        CGPoint scrollPoint = CGPointMake(0.0, activeField.frame.origin.y-kbSize.height);
//        [scrollView setContentOffset:scrollPoint animated:YES];
//    }
}

// Called when the UIKeyboardWillHideNotification is sent
- (void)keyboardWillBeHidden:(NSNotification*)aNotification {
    NSLog(@"Before: bodyField.frame.size.height=%f", bodyField.frame.size.height);
    
    CGRect bodyFieldFrame = [bodyField frame];
//    bodyFieldFrame.size.height = originalBodyFieldHeight;
    bodyFieldFrame.size.height = measuredBodyFieldHeight; // I need to set it back to the previously measured height (which is logical), just don't know why it is different from the specified height in IB, which is the original size as measured in viewDidLoad
    [bodyField setFrame:bodyFieldFrame];
    
    NSLog(@"After: bodyField.frame.size.height=%f", bodyField.frame.size.height);
    
    // TODO: same, use the scrolling
//    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
//    scrollView.contentInset = contentInsets;
//    scrollView.scrollIndicatorInsets = contentInsets;
}

//- (void)textFieldDidBeginEditing:(UITextField *)textField
//{
//    activeField = textField;
//}
//
//- (void)textFieldDidEndEditing:(UITextField *)textField
//{
//    activeField = nil;
//}

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    activeField = textView;
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    activeField = nil;
}

@end
