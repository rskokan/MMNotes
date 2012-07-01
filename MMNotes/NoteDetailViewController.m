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
#import "GAUtils.h"

@interface NoteDetailViewController ()

@end

@implementation NoteDetailViewController

@synthesize note = _note, dismissBlock = _dismissBlock, isNew = _isNew;

- (id)initForNewNote:(BOOL)new {
    self = [super initWithNibName:@"NoteDetailViewController" bundle:nil];
    if (self) {
        _isNew = new;
        
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

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[GAUtils sharedUtils] trackPageView:@"NoteDetail"];
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
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        self.view.backgroundColor = [UIColor groupTableViewBackgroundColor];
    } else {
        self.view.backgroundColor = [UIColor lightGrayColor];
    }
    
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
    
    // Hide keyboard when the scroll view is tapped
    UITapGestureRecognizer *backgroundTapGestureRecignizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleScrollViewTap:)];
    backgroundTapGestureRecignizer.cancelsTouchesInView = NO;
    [scrollView addGestureRecognizer:backgroundTapGestureRecignizer];
    
    // Find the position where it was tapped in the bodyField in order to scroll to that point when the keyboard is shown.
    // It is because when using UIKeyboardWillShowNotification, the bodyField.selectedTextRange is nill (it is ok with UIKeyboardDidShowNotification, but then I cannot animate the scrolling together with the keyboard animation.
    // TODO: need to solve the ordr of multiple recognizers. This one must be called before the UITextView standard one
//    UITapGestureRecognizer *bodyFieldTapGestureRecignizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleBodyFieldTap:)];
//    bodyFieldTapGestureRecignizer.cancelsTouchesInView = NO;
//    bodyFieldTapGestureRecignizer.delegate = self;
//    [bodyField addGestureRecognizer:bodyFieldTapGestureRecignizer];
    
    [self registerNotifications];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    
    titleField = nil;
    bodyField = nil;
    tagsButton = nil;
    scrollView = nil;
    
    [self deregisterNotifications];
}

- (void)dealloc {
    [self deregisterNotifications];
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

- (IBAction)showTagsPicker:(id)sender {
    TagsListViewController *tagsListVC = [[TagsListViewController alloc] initWithMode:TagsListViewControllerModeSelect];
    [tagsListVC setNote:[self note]];
    [[self navigationController] pushViewController:tagsListVC animated:YES];
}

- (IBAction)backgroundTapped:(id)sender {
    [[self view] endEditing:YES];
}

- (void)handleScrollViewTap:(UIGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateEnded) {
        [[self view] endEditing:YES];
    }
}

- (void)handleBodyFieldTap:(UIGestureRecognizer *)sender {
    NSLog(@"%@", NSStringFromSelector(_cmd));
    if (sender.state == UIGestureRecognizerStateEnded) {
        tappedLocationInBodyField = [sender locationInView:bodyField];
        NSLog(@"setting: tappedLocationInBodyField.y=%0.0f", tappedLocationInBodyField.y);
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    // To allow proper functionality of my and UITextView gesture recognizers
    // TODO: but how to guarantee the order? I need that my handleBodyFieldTap: is called before the standard UITextView's one
    return YES;
}


- (IBAction)titleFieldChanged:(id)sender {
    [[self navigationItem] setTitle:[titleField text]];
}

// Hide keyboard when return is pressed
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

// The camera button has been clicked, show the photo gallery
- (void)showPhotos:(id)sender {
    ImageGalleryViewController *igvc = [[ImageGalleryViewController alloc] initWithNote:[self note]];
    [[self navigationController] pushViewController:igvc animated:YES];
}

- (void)registerNotifications {
    // TODO: It will be better to use UIKeyboardDidShowNotification to animate the view scrolling together with the keyboard show animation, but with UIKeyboardDidShowNotification the selectedTextRange is nil. So find another way how to determine the cursor position in the textField
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(storeUpdated:)
                                                 name:MMNDataStoreUpdateNotification object:nil];
}

- (void)deregisterNotifications {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

// The store has been updated
- (void)storeUpdated:(NSNotification *)notif {
    [self updateFavoriteItemStatus];
    [self updatePhotoItemStatus];
}

// Called when the UIKeyboardDidShowNotification is sent.
- (void)keyboardWasShown:(NSNotification *)notif {
    NSDictionary *info = [notif userInfo];
    CGRect kbRect = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    // conversion from screen to view coordinates
    kbRect = [self.view convertRect:kbRect fromView:nil];
    
    CGRect visibleRect = [[self view] frame];
    CGRect extendedRect = CGRectMake(0.0, 0.0, visibleRect.size.width, visibleRect.size.height + kbRect.size.height);
    scrollView.contentSize = extendedRect.size;
    
    // Either titleField or bodyField
    UIView<UITextInput> *activeTextField = (UIView<UITextInput> *)activeField;
    
    CGFloat newVisibleOriginY;
    if (activeTextField.selectedTextRange != nil) {
        CGPoint cursorPosition = [activeTextField caretRectForPosition:activeTextField.selectedTextRange.start].origin;
        newVisibleOriginY = activeTextField.frame.origin.y + cursorPosition.y;
    } else {
        // Tapped in bodyField, using the location from the tap
        newVisibleOriginY = activeTextField.frame.origin.y + tappedLocationInBodyField.y;
        NSLog(@"Using tappedLocationInBodyField.y=%0.0f", tappedLocationInBodyField.y);
    }
    
    NSValue *animationDurationValue = [info objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSTimeInterval animationDuration;
    [animationDurationValue getValue:&animationDuration];
    [UIView beginAnimations:@"ScrollForKeyboard" context:NULL];
    [UIView setAnimationDuration:animationDuration];
    
    
    CGRect newVisibleRect = CGRectMake(0.0, newVisibleOriginY, visibleRect.size.width, visibleRect.size.height);
    
    [scrollView scrollRectToVisible:newVisibleRect animated:YES];
    [UIView commitAnimations];
    
    [scrollView flashScrollIndicators];
}

// Called when the UIKeyboardWillHideNotification is sent
- (void)keyboardWillBeHidden:(NSNotification*)aNotification {
    NSDictionary *info = [aNotification userInfo];
    NSValue *animationDurationValue = [info objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSTimeInterval animationDuration;
    [animationDurationValue getValue:&animationDuration];
    [UIView beginAnimations:@"ScrollForKeyboard" context:NULL];
    [UIView setAnimationDuration:animationDuration];
    
    CGRect visibleRect = [[self view] frame];
    scrollView.contentSize = visibleRect.size;
    
    [UIView commitAnimations];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    activeField = textField;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    activeField = nil;
}

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    activeField = textView;
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    activeField = nil;
}

@end
