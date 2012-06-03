//
//  TagsListViewController.h
//  MMNotes
//
//  Created by Radek Skokan on 5/31/12.
//  Copyright (c) 2012 radek@skokan.name. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MMNTag;
@class MMNNote;

typedef enum {
    TagsListViewControllerModeView,
    TagsListViewControllerModeAdd,
    TagsListViewControllerModeSelect
} TagsListViewControllerMode;

// List of Tags.
// 
@interface TagsListViewController : UITableViewController <UITableViewDataSource, UITableViewDelegate>
{
    // The index path of the first cell in a table (row 0, section 0)
    NSIndexPath *kMMNIndexPathZero;
}

@property (nonatomic) TagsListViewControllerMode mode;

@property (nonatomic, strong) MMNTag *currentTag;

// The actual item for which selected tags are being displayed (in mode TagsListViewControllerModeSelect)
@property (nonatomic, weak) MMNNote *note;

// The designated initializer
- (id)initWithMode:(TagsListViewControllerMode)mode;

// Displays a view to add a new Tag
- (IBAction)addNewTag:(id)sender;

// Confirms adding of newTag
- (void)confirmAddingNewTag:(id)sender;

@end
