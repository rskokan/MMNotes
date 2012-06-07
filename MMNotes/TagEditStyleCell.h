//
//  TagEditStyleCell.h
//  MMNotes
//
//  Created by Radek Skokan on 6/1/12.
//  Copyright (c) 2012 radek@skokan.name. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TagsListViewController;

typedef enum {
    TagEditStyleCellModeAdd,
    TagEditStyleCellModeEdit
} TagEditStyleCellMode;

// This cell is used in edit mode of the tag list.
// It has one text field, where the tag name can be changed.
//
@interface TagEditStyleCell : UITableViewCell <UITextFieldDelegate>
{
    UITextField *textField;
}

// The tag name displayed in the cell's text field
@property (nonatomic, copy) NSString *tagName;

// Must be specified when mode=TagEditStyleCellModeAdd
@property (nonatomic, strong) TagsListViewController *controller;

// In which mode the cell is displayed
@property (nonatomic) TagEditStyleCellMode mode;

@end
