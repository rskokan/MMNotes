//
//  TagsListViewController.m
//  MMNotes
//
//  Created by Radek Skokan on 5/31/12.
//  Copyright (c) 2012 radek@skokan.name. All rights reserved.
//

#import "TagsListViewController.h"
#import "MMNDataStore.h"
#import "MMNTag.h"
#import "MMNNote.h"
#import "TagEditStyleCell.h"
#import "NotesListViewController.h"

@implementation TagsListViewController

@synthesize mode, currentTag, note;

// The designated initializer.
- (id)initWithMode:(TagsListViewControllerMode)m {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        [self setMode:m];
        NSString *title;
        if (m == TagsListViewControllerModeSelect) {
            title = @"Select tags";
            [self displaySelectModeBarButtonItems];
        } else {
            title = @"Tags";
            [self displayStandardModeBarButtonItems];
        }
        [[self navigationItem] setTitle:title];
        [self setTitle:title];
    }
    
    return self;
}

- (id)init {
    @throw [NSException exceptionWithName:@"Wrong initializer" reason:@"Use initWithMode:" userInfo:nil];
}

// Must always override super's designated initializer.
- (id)initWithStyle:(UITableViewStyle)style {
    return [self init];
}

- (void)displayAddTagBarButton {
    UIBarButtonItem *bbiAdd = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:
                               UIBarButtonSystemItemAdd target:self action:@selector(addNewTag:)];
    [[self navigationItem] setRightBarButtonItem:bbiAdd];
}

// In the tag selection mode no special buttons need to be displayed. Just the standard navigation one to go back.
- (void)displaySelectModeBarButtonItems {
    [[self navigationItem] setLeftBarButtonItem:nil];
    [[self navigationItem] setRightBarButtonItem:nil];
}

// Displays Edit - Add bar buttons, for standard mode
- (void)displayStandardModeBarButtonItems {
    [[self navigationItem] setLeftBarButtonItem:[self editButtonItem]];
    [self displayAddTagBarButton];    
}

// Displays Cancel - Done bar buttons, for the mode when adding a new tag
- (void)displayAddingTagModeBarButtonItems {
    UIBarButtonItem *bbiCancel = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:
                                  UIBarButtonSystemItemCancel target:self action:@selector(cancelAddingNewTag:)];
    [[self navigationItem] setLeftBarButtonItem:bbiCancel];
    UIBarButtonItem *bbiDone = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:
                                UIBarButtonSystemItemDone target:self action:@selector(confirmAddingNewTag:)];
    [[self navigationItem] setRightBarButtonItem:bbiDone];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    
    if (editing) {
        // Hide the Add New Tag bar button (the right one)
        [[self navigationItem] setRightBarButtonItem:nil];
    } else {
        [self updateDataModelAfterEditing];
        [self displayAddTagBarButton];
    }
    
    // Redraw the table to display/get rid off the input text fields
    [[self tableView] reloadData];
}

// In the edit mode, users can cange tag names. So when leaving the edit mode,
// we will iterate through all the rows and update the relevant element in the tag store
- (void)updateDataModelAfterEditing {
    NSMutableArray *tagsToBeRemoved = [NSMutableArray array];
    
    NSArray *allTags = [[MMNDataStore sharedStore] allTags];
    for (int i = 0; i < [allTags count]; i++) {
        MMNTag *tag = [allTags objectAtIndex:i];
        NSIndexPath *ip = [NSIndexPath indexPathForRow:i inSection:0];
        TagEditStyleCell *cell = (TagEditStyleCell *)[[self tableView] cellForRowAtIndexPath:ip]; // In edit mode, so the cell should be TagEditStyleCell
        NSString *editedText = [cell tagName];
        NSString *trimmedTagText = [editedText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        NSLog(@"Old tag text=%@, new text=%@", [tag name], trimmedTagText);
        if ([trimmedTagText length] == 0) {
            [tagsToBeRemoved addObject:tag];
        } else {
            [tag setName:trimmedTagText];
        }
    }
    
    [[MMNDataStore sharedStore] removeTags:tagsToBeRemoved];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //TODO: register custom table view cells
    //    UINib *nib = [UINib nibWithNibName:@"HomepwnerItemCell" bundle:nil];
    //    [[self tableView] registerNib:nib forCellReuseIdentifier:@"HomepwnerItemCell"];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    int allTagsCount = [[[MMNDataStore sharedStore] allTags] count];
    if (mode == TagsListViewControllerModeAdd)
        return allTagsCount + 1;
    
    return allTagsCount;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;
    
    if ([self isEditing] || (mode == TagsListViewControllerModeAdd && [indexPath row] == 0)) {
        // We are editing tags or creating a new one, so insert an input field
        cell = [tableView dequeueReusableCellWithIdentifier:@"TagEditStyleCell"];
        if (!cell) {
            cell = [[TagEditStyleCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"TagEditStyleCell"];
        }
        
        if ([self isEditing]) {
            // Existing note in edit mode, pre-fill the existing tag name
            MMNTag *tag = [[[MMNDataStore sharedStore] allTags] objectAtIndex:[indexPath row]];
            [(TagEditStyleCell *)cell setTagName:[tag name]];
            [(TagEditStyleCell *)cell setMode:TagEditStyleCellModeEdit];
        } else {
            // Creating a new Tag
            [(TagEditStyleCell *)cell setTagName:@""];
            [(TagEditStyleCell *)cell setController:self];
            [(TagEditStyleCell *)cell setMode:TagEditStyleCellModeAdd];
            [cell becomeFirstResponder];
        }
        
    } else {
        // Only displaying tags, no editing nor adding
        cell = [tableView dequeueReusableCellWithIdentifier:@"UITableViewCell"];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"UITableViewCell"];
        }
        MMNTag *tag = [[[MMNDataStore sharedStore] allTags] objectAtIndex:[indexPath row]];
        [[cell textLabel] setText:[tag name]];
        [[cell detailTextLabel] setText:[NSString stringWithFormat:@"%d", [[tag notes] count]]];
        
        // Checkmarks for tag select mode (assigning tags to a note)
        if (mode == TagsListViewControllerModeSelect) {
            if ([[note tags] containsObject:tag]) {
                [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
            } else {
                [cell setAccessoryType:UITableViewCellAccessoryNone];
            }
        }
    }
    
    return cell;
    
    // TODO: Use custom cell
    //    HomepwnerItemCell *cell = [tableView dequeueReusableCellWithIdentifier:@"HomepwnerItemCell"];
    //    [[cell nameLabel] setText:[item itemName]];
    //    [[cell serialNumberLabel] setText:[item serialNumber]];
    //    NSString *currencySymbol = [[NSLocale currentLocale] objectForKey:NSLocaleCurrencySymbol];
    //    [[cell valueLabel] setText:[NSString stringWithFormat:@"%@%d", currencySymbol, [item valueInDollars]]];
    //    [[cell thumbnailView] setImage:[item thumbnail]];
    //    [cell setController:self];
    //    [cell setTableView:tableView];
}

// Confirms adding of newTag
- (void)confirmAddingNewTag:(id)sender {
    NSIndexPath *indexPathZero = [NSIndexPath indexPathForRow:0 inSection:0];
    TagEditStyleCell *cellZero = (TagEditStyleCell *)[[self tableView] cellForRowAtIndexPath:indexPathZero]; // The zeroth cell should be the TagEditStyleCell when adding
    NSString *trimmedTagText = [[cellZero tagName] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([trimmedTagText length] == 0)
        [self cancelAddingNewTag:sender];
    
    [currentTag setName:trimmedTagText];
    [[MMNDataStore sharedStore] ensureUniqueTagName:currentTag];
    [self setMode:TagsListViewControllerModeView];
    [self displayStandardModeBarButtonItems];
    [[self tableView] reloadData];
}

// Cancels adding of the newTag, which is in progress.
- (void)cancelAddingNewTag:(id)sender {
    [[MMNDataStore sharedStore] removeTag:[self currentTag]];
    [self setMode:TagsListViewControllerModeView];
    [self displayStandardModeBarButtonItems];
    [[self tableView] reloadData];
}

- (IBAction)addNewTag:(id)sender {
    [self setMode:TagsListViewControllerModeAdd];
    [self displayAddingTagModeBarButtonItems];
    NSIndexPath *indexPathZero = [NSIndexPath indexPathForRow:0 inSection:0];
    [[self tableView] insertRowsAtIndexPaths:[NSArray arrayWithObject:indexPathZero] withRowAnimation:UITableViewRowAnimationAutomatic];    
    [self setCurrentTag:[[MMNDataStore sharedStore] createTag]];
    
    
    
    //    TagDetailViewController *detailVC = [[TagDetailViewController alloc] initForNewTag:YES];
    //    [detailVC setTag:newTag];
    //    [detailVC setDismissBlock:^{
    //        [[self tableView] reloadData];
    //    }];
    //    UINavigationController *navCtrl = [[UINavigationController alloc] initWithRootViewController:detailVC];
    //    [navCtrl setModalPresentationStyle:UIModalPresentationFormSheet];
    //    [self presentViewController:navCtrl animated:YES completion:nil];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        MMNDataStore *store = [MMNDataStore sharedStore];
        NSArray *tags = [store allTags];
        MMNTag *tag = [tags objectAtIndex:[indexPath row]];
        [store removeTag:tag];
        
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
    [[MMNDataStore sharedStore] moveTagAtIndex:[sourceIndexPath row] toIndex:[destinationIndexPath row]];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    MMNTag *tag = [[[MMNDataStore sharedStore] allTags] objectAtIndex:[indexPath row]];
    
    if (mode == TagsListViewControllerModeSelect) {
        // Mode of selecting tags for a note
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        
        if ([cell accessoryType] == UITableViewCellAccessoryCheckmark) {
            NSLog(@"Removing tag %@ from note %@", tag, note);
            [note removeTagsObject:tag];
            [cell setAccessoryType:UITableViewCellAccessoryNone];
        } else {
            NSLog(@"Adding tag %@ to note %@", tag, note);
            [note addTagsObject:tag];
            [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
        }
        [[cell detailTextLabel] setText:[NSString stringWithFormat:@"%d", [[tag notes] count]]];
        
    } else if (mode == TagsListViewControllerModeView) {
        // Through tapping on a tag in the View mode we display notes with the tag
        NotesListViewController *notesListVC = [[NotesListViewController alloc] initWithMode:NotesListViewControllerModeNotesForTag forTag:tag];
        [[self navigationController] pushViewController:notesListVC animated:YES];
    }
    
    // TODO
    //    MMNTag *tag = [[[MMNDataStore sharedStore] allTags] objectAtIndex:[indexPath row]];
    //    TagDetailViewController *detailVC = [[TagDetailViewController alloc] initForNewTag:NO];
    //    [detailVC setTag:tag];
    //    
    //    [[self navigationController] pushViewController:detailVC animated:YES];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[self tableView] reloadData];
}

@end
