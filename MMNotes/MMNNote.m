//
//  MMNNote.m
//  MMNotes
//
//  Created by Radek Skokan on 5/30/12.
//  Copyright (c) 2012 radek@skokan.name. All rights reserved.
//

#import "MMNNote.h"
#import "MMNAttachment.h"
#import "MMNTag.h"

const int MMNNoteMaxDisplayTextLength = 20;

@implementation MMNNote

@dynamic title;
@dynamic body;
@dynamic isFavorite;
@dynamic dateModified;
@dynamic order;
@dynamic tags;
@dynamic attachments;

- (NSString *)displayTextFromDate {
    static NSDateFormatter *dateFormatter = nil;
    
    if (!dateFormatter) {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
        [dateFormatter setDateStyle:NSDateFormatterShortStyle];
    }
    
    return [NSString stringWithFormat:@"[%@]", [dateFormatter stringFromDate:[self dateModified]]];
}

- (NSString *)displayText {
     
    
    if ([[self title] length] > 0)
        return [self title];
    
    NSString *trimmedBody = [[self body] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([trimmedBody length] > 0) {
        int toIndex = [trimmedBody length] > MMNNoteMaxDisplayTextLength ? MMNNoteMaxDisplayTextLength : [trimmedBody length];
        return [trimmedBody substringToIndex:toIndex];
    }
    
    return [self displayTextFromDate];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"[MMNNote(title=%@, dateModified=%@, order=%f]", [self title], [self dateModified], [self order]];
}

- (BOOL)hasNoText {
    return [[self title] length] == 0 && [[self body] length] == 0 && [[self attachments] count] == 0;
}

- (NSString *)tagsAsOrderedString {
    return nil;
}

// TODO: Add some thumbnail preparation like in BNRItem.m

@end
