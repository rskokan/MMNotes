//
//  NotesListViewController.m
//  MMNotes
//
//  Created by Radek Skokan on 5/30/12.
//  Copyright (c) 2012 radek@skokan.name. All rights reserved.
//

#import "NotesListViewController.h"
#import "NoteDetailViewController.h"
#import "MMNDataStore.h"
#import "MMNNote.h"
#import "MMNTag.h"

@implementation NotesListViewController

@synthesize mode = _mode, tag = _tag;

// The designated initializer.
- (id)initWithMode:(NotesListViewControllerMode)m {
    return [self initWithMode:m forTag:nil];
}

- (id)initWithMode:(NotesListViewControllerMode)m forTag:(id)t {
    self = [super initWithStyle:UITableViewStylePlain];
    
    if (self) {
        _mode = m;
        _tag = t;
        NSString *title;
        switch (m) {
            case NotesListViewControllerModeAllNotes: {
                [[self navigationItem] setLeftBarButtonItem:[self editButtonItem]];
                UIBarButtonItem *bbiAdd = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:
                                           UIBarButtonSystemItemAdd target:self action:@selector(addNewNote:)];
                [[self navigationItem] setRightBarButtonItem:bbiAdd];
                title = @"Notes";
                [[self tabBarItem] setImage:[UIImage imageNamed:@"note_tabbar"]];
            }
                break;
                
            case NotesListViewControllerModeFavoriteNotes: {
                [[self navigationItem] setLeftBarButtonItem:nil];
                [[self navigationItem] setRightBarButtonItem:nil];
                title = @"Favorites";
                [[self tabBarItem] setImage:[UIImage imageNamed:@"star_tabbar"]];
            }
                break;
                
            case NotesListViewControllerModeNotesForTag: {
                [[self navigationItem] setLeftBarButtonItem:nil];
                [[self navigationItem] setRightBarButtonItem:nil];
                title = [NSString stringWithFormat:@"Notes Tagged %@", [[self tag] name]];
                
                // Not at the top level, hide the main tabbar
                [self setHidesBottomBarWhenPushed:YES];
            }
                break;
                
            default:
                NSLog(@"Unknown value of NotesListViewControllerMode");
                break;
        }
        
        [[self navigationItem] setTitle:title];
        [[self tabBarItem] setTitle:title];     
    }
    
    return self;
}

- (id)init {
    @throw [NSException exceptionWithName:@"Wrong initializer" reason:@"Use initWithMode:" userInfo:nil];
    return nil;
}

// Must always override super's designated initializer.
- (id)initWithStyle:(UITableViewStyle)style {
    return [self init];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //TODO: register custom table view cells
    //    UINib *nib = [UINib nibWithNibName:@"HomepwnerItemCell" bundle:nil];
    //    [[self tableView] registerNib:nib forCellReuseIdentifier:@"HomepwnerItemCell"];
}

// Returns an array of notes depending on the current mode:
// - all notes for NotesListViewControllerModeAllNotes,
// - favorited notes for NotesListViewControllerModeFavoriteNotes,
// - notes with a given tag for NotesListViewControllerModeNotesForTag
- (NSArray *)actualNotes {
    switch ([self mode]) {
        case NotesListViewControllerModeAllNotes:
            return [[MMNDataStore sharedStore] allNotes];
            break;
        case NotesListViewControllerModeFavoriteNotes:
            return [[MMNDataStore sharedStore] favoritedNotes];
            break;
        case NotesListViewControllerModeNotesForTag:
            return [[MMNDataStore sharedStore] notesTaggedWith:[self tag]];
            break;
        default:
            NSLog(@"Unknown value of NotesListViewControllerMode");
            break;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[self actualNotes] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MMNNote *note = [[self actualNotes] objectAtIndex:[indexPath row]];
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UITableViewCell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"UITableViewCell"];
    }
    
    [[cell textLabel] setText:[note displayText]];
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

- (IBAction)addNewNote:(id)sender {
    MMNNote *newNote = [[MMNDataStore sharedStore] createNote];
    NoteDetailViewController *detailVC = [[NoteDetailViewController alloc] initForNewNote:YES];
    [detailVC setNote:newNote];
    [detailVC setDismissBlock:^{
        [[self tableView] reloadData];
    }];
    UINavigationController *navCtrl = [[UINavigationController alloc] initWithRootViewController:detailVC];
    [navCtrl setModalPresentationStyle:UIModalPresentationFormSheet];
    [self presentViewController:navCtrl animated:YES completion:nil];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        MMNNote *note = [[self actualNotes] objectAtIndex:[indexPath row]];
        [[MMNDataStore sharedStore] removeNote:note];
        [[MMNDataStore sharedStore] saveChanges];
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
    [[MMNDataStore sharedStore] moveNoteAtIndex:[sourceIndexPath row] toIndex:[destinationIndexPath row]];
            [[MMNDataStore sharedStore] saveChanges];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    MMNNote *note = [[self actualNotes] objectAtIndex:[indexPath row]];
    NoteDetailViewController *detailVC = [[NoteDetailViewController alloc] initForNewNote:NO];
    [detailVC setNote:note];
    
    [[self navigationController] pushViewController:detailVC animated:YES];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[self tableView] reloadData];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

@end
