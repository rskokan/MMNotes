//
//  NoteDetailViewController.m
//  MMNotes
//
//  Created by Radek Skokan on 5/30/12.
//  Copyright (c) 2012 radek@skokan.name. All rights reserved.
//

#import "NoteDetailViewController.h"
#import "MMNDataStore.h"
#import "MMNNote.h"
#import "TagsListViewController.h"

@interface NoteDetailViewController ()

@end

@implementation NoteDetailViewController

@synthesize note, dismissBlock;

- (id)initForNewNote:(BOOL)isNew {
    self = [super initWithNibName:@"NoteDetailViewController" bundle:nil];
    if (self) {
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

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    @throw [NSException exceptionWithName:@"Wrong initializer" reason:@"Use initForNewNote:" userInfo:nil];
    return nil;
}

- (void)save:(id)sender {
    [[self presentingViewController] dismissViewControllerAnimated:YES completion:dismissBlock];
}

- (void)cancel:(id)sender {
    [[MMNDataStore sharedStore] removeNote:note];
    [[self presentingViewController] dismissViewControllerAnimated:YES completion:dismissBlock];
}

- (void)setNote:(MMNNote *)n {
    note = n;
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
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
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

// Hide keyboard when return is pressed
// TODO: check; we also have more text fields
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

@end
