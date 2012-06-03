//
//  NotesListViewController.h
//  MMNotes
//
//  Created by Radek Skokan on 5/30/12.
//  Copyright (c) 2012 radek@skokan.name. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MMNTag;

typedef enum {
    NotesListViewControllerModeAllNotes,
    NotesListViewControllerModeFavoriteNotes,
    NotesListViewControllerModeNotesForTag
} NotesListViewControllerMode;

// A view controller to display list of notes (and also favorite notes; it has 2 use cases).
// Supported notes operations:
//   1) edit: change notes order, delete notes
//   2) add a new note
//   3) select an existing note and go navigate to its detail
// 
// The view of this ctrl issupposed to be displayed on a paent tab view together with list of tags
//
@interface NotesListViewController : UITableViewController <UITableViewDataSource, UITableViewDelegate>
{

}

@property (nonatomic) NotesListViewControllerMode mode;

// When displaying only tags for a given node in the NotesListViewControllerModeNotesForTag mode, this specifies the tag
@property (nonatomic, weak) MMNTag *tag;

// The designated initializer.
- (id)initWithMode:(NotesListViewControllerMode)mode;

// To display notes for a given tag
- (id)initWithMode:(NotesListViewControllerMode)mode forTag:tag;

// Displays a view to add a new Note
- (IBAction)addNewNote:(id)sender;

@end
