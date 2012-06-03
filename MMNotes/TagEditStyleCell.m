//
//  TagEditStyleCell.m
//  MMNotes
//
//  Created by Radek Skokan on 6/1/12.
//  Copyright (c) 2012 radek@skokan.name. All rights reserved.
//

#import "TagEditStyleCell.h"
#import "TagsListViewController.h"

@implementation TagEditStyleCell

@synthesize controller, mode;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        textField = [[UITextField alloc] initWithFrame:[self bounds]];
        [textField setReturnKeyType:UIReturnKeyDone];
        [textField setContentVerticalAlignment:UIControlContentVerticalAlignmentCenter];
        [textField setPlaceholder:@"Tag name"];
        [textField setDelegate:self];
        [[self contentView] addSubview:textField];
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)dealloc {
    textField = nil;
}

- (void)setTagName:(NSString *)tagName {
    [textField setText:tagName];
}

- (NSString *)tagName {
    return [textField text];
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (BOOL)becomeFirstResponder {
    return [textField becomeFirstResponder];
}

- (BOOL)textFieldShouldReturn:(UITextField *)tf {
    [textField resignFirstResponder];
    if (mode == TagEditStyleCellModeAdd) {
        [[self controller] confirmAddingNewTag:self]; // The controler must when adding a new tag; not for editing
    }
    
    return YES;
}

@end
