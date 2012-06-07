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
    
    // Sorting tags by their order property
    static NSArray *tagSortDescriptors = nil;
    if (!tagSortDescriptors)
        tagSortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"order" ascending:YES]];
    
    [titleField setText:[[self note] title]];
    [bodyField setText:[[self note] body]];
    
    NSMutableString *tagString = [NSMutableString string];
    if ([[[self note] tags] count] == 0)
        [tagString appendString:@"No tags"];
    else {
        [[[[self note] tags] sortedArrayUsingDescriptors:tagSortDescriptors] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            if ([tagString length] > 0)
                [tagString appendString:@", "];
            [tagString appendString:[obj name]];
        }];
    }
    [tagString insertString:@"[" atIndex:0];
    [tagString appendString:@"]"];
    
    [tagsButton setTitle:tagString forState:UIControlStateNormal];
    
    [self updateFavoriteItemStatus];
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
    
    if ([[[self note] images] count] > 0)
        [photoItem setTintColor:[UIColor yellowColor]];
    else
        [photoItem setTintColor:nil];
    
    [self setToolbarItems:[NSArray arrayWithObjects:favoriteItem, flexiSpace, photoItem, flexiSpace, trashItem, nil] animated:YES];
    
    // TODO: set some better background color for iPad?
}

- (void)viewDidUnload
{
    titleField = nil;
    bodyField = nil;
    tagsButton = nil;
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
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

@end
