//
//  NoteListCell.m
//  MMNotes
//
//  Created by Radek Skokan on 6/8/12.
//  Copyright (c) 2012 radek@skokan.name. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "NoteListCell.h"
#import "MMNNote.h"

@implementation NoteListCell

@synthesize note = _note;

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
}

- (void)setNote:(MMNNote *)note {
    _note = note;
    [titleLabel setText:[note displayText]];
    [tagsLabel setText:[note orderedTagsString]];;
    [starButton setHidden:![[note isFavorite] boolValue]];
    [photoButton setHidden:[[note images] count] <= 0];
    [micButton setHidden:YES]; // will be supported in future versions
}

@end
