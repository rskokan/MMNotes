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
@dynamic isEncrypted;
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
    
    return [NSString stringWithFormat:@"(%@)", [dateFormatter stringFromDate:[self dateModified]]];
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
    return [NSString stringWithFormat:@"[MMNNote(title=%@, dateModified=%@, order=%@]", [self title], [self dateModified], [self order]];
}

- (BOOL)hasNoText {
    return [[self title] length] == 0 && [[self body] length] == 0 && [[self attachments] count] == 0;
}

- (BOOL)isEmpty {
    return ([[[self title] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] == 0)
    && ([[[self body] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] == 0)
    && ([[self attachments] count] == 0);
}

- (NSArray *)orderedImages {
    static NSPredicate *imageTypePredicate = nil;
    NSSortDescriptor *sort = nil;
    if (!imageTypePredicate || !sort) {
        imageTypePredicate = [NSPredicate predicateWithFormat:@"SELF.attachmentType == %d", MMNAttachmentTypeImage];
        // Sort it by date taken
        sort = [NSSortDescriptor sortDescriptorWithKey:@"dateModified" ascending:YES];
    }
    
    // Filter only images
    NSSet *imageSet = [[self attachments] filteredSetUsingPredicate:imageTypePredicate];
    
    return [imageSet sortedArrayUsingDescriptors:[NSArray arrayWithObject:sort]];
}

- (NSSet *)images {
    static NSPredicate *imageTypePredicate = nil;
    if (!imageTypePredicate) {
        imageTypePredicate = [NSPredicate predicateWithFormat:@"SELF.attachmentType == %d", MMNAttachmentTypeImage];
    }
    
    // Filter only images
    return [[self attachments] filteredSetUsingPredicate:imageTypePredicate];
}

- (NSString *)orderedTagsString {
    // Sorting tags by their order property
    static NSArray *tagSortDescriptors = nil;
    if (!tagSortDescriptors)
        tagSortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"order" ascending:YES]];
    
    NSMutableString *tagString = [NSMutableString string];
    if ([[self tags] count] == 0)
        [tagString appendString:@" "];
    else {
        [[[self tags] sortedArrayUsingDescriptors:tagSortDescriptors] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            if ([tagString length] > 0)
                [tagString appendString:@", "];
            [tagString appendString:[obj name]];
        }];
    }
    [tagString insertString:@"[" atIndex:0];
    [tagString appendString:@"]"];
    
    return tagString;
}

- (void)willSave {
    //    NSLog(@"willSave %@; hasChanges: %d, isInserted: %d, isDeleted: %d, isUpdated: %d, changedValues: %d, changedValuesForCurrentEvent: %d", self, [self hasChanges], [self isInserted], [self isDeleted], [self isUpdated], [[self changedValues] count], [[self changedValuesForCurrentEvent] count]);
    
    // Update dateModified only when it has not been already updated
    if (([[self changedValues] count] > 0) && (! [self isDeleted])
        && (! [[[self changedValues] allKeys] containsObject:@"dateModified"])) {
//        NSLog(@"MMNNote.willSave: updating dateModified; changedValues: %@", [self changedValues]);
        [self setDateModified:[NSDate date]];
    }
}

// TODO: Add some thumbnail preparation like in BNRItem.m

@end
