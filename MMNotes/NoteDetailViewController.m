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

@interface NoteDetailViewController ()

@end

@implementation NoteDetailViewController

@synthesize note, dismissBlock, isNew;

- (id)initForNewNote:(BOOL)new {
    self = [super initWithNibName:@"NoteDetailViewController" bundle:nil];
    if (self) {
        isNew = new;
        if (isNew) {
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

- (void)save:(id)sender {
    [[self presentingViewController] dismissViewControllerAnimated:YES completion:dismissBlock];
}

- (void)cancel:(id)sender {
    // Confirmation if the note has some contents
    [note setTitle:[titleField text]];
    [note setBody:[bodyField text]];
    
    if ([note isEmpty]) {
        // Discard the new note only when it is empty
        [[MMNDataStore sharedStore] removeNote:note];
        [[self presentingViewController] dismissViewControllerAnimated:YES completion:dismissBlock];
    } else {
        // Otherwise ask for confirmation
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Discard note" message:@"The note is not empty. Do you want to discard it?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Discard", nil];
        [alert show];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        // The user confirmed to discard the new not empty note
        NSLog(@"The user confirmed to discard the new not empty note");
        [[MMNDataStore sharedStore] removeNote:note];
        [[self presentingViewController] dismissViewControllerAnimated:YES completion:dismissBlock];
    } else {
        NSLog(@"The user canceled discarding the note");
    }
}

- (void)setNote:(MMNNote *)n {
    note = n;
    if (!isNew)
        [[self navigationItem] setTitle:[note displayText]];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Sorting tags by their order property
    static NSArray *tagSortDescriptors = nil;
    if (!tagSortDescriptors)
        tagSortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"order" ascending:YES]];
    
    [titleField setText:[note title]];
    [bodyField setText:[note body]];
    
    NSMutableString *tagString = [NSMutableString string];
    if ([[note tags] count] == 0)
        [tagString appendString:@"No tags"];
    else {
        [[[note tags] sortedArrayUsingDescriptors:tagSortDescriptors] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            if ([tagString length] > 0)
                [tagString appendString:@", "];
            [tagString appendString:[obj name]];
        }];
    }
    [tagString insertString:@"[" atIndex:0];
    [tagString appendString:@"]"];
    
    [tagsButton setTitle:tagString forState:UIControlStateNormal];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    // Clear first responder (hide keyboard)
    [[self view] endEditing:YES];
    
    [note setTitle:[titleField text]];
    [note setBody:[bodyField text]];
    [[MMNDataStore sharedStore] saveChanges];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    [[bodyField layer] setBorderWidth:1];
    [[bodyField layer] setBorderColor:[[UIColor grayColor] CGColor]];
    
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
    [tagsListVC setNote:note];
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

@end
