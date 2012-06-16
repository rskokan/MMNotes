//
//  MMNDataStore.h
//  MMNotes
//
//  Created by Radek Skokan on 5/30/12.
//  Copyright (c) 2012 radek@skokan.name. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MMNNote;
@class MMNTag;
@class MMNAttachment;

extern NSString * const MMNDataStoreUpdateNotification;

// A store object for storing notes and tags into SQLite.
// This class is a singleton.
//
@interface MMNDataStore : NSObject
{
    NSMutableArray *allNotes;
    NSMutableArray *allTags;
    
    NSManagedObjectContext *ctx;
    NSManagedObjectModel *model;
}

// Returns the singleton instance
+ (MMNDataStore *)sharedStore;

// Creates a new Note
- (MMNNote *)createNote;

// Removes a Note
- (void)removeNote:(MMNNote *)note;

// Returns all Notes
- (NSArray *)allNotes;

// Returns notes marked as favorite
- (NSArray *)favoritedNotes;

// Returns notes tagged with the given tag
- (NSArray *)notesTaggedWith:(MMNTag *)tag;

// Moves the Note item in the list at specified position inthe GUI list
- (void)moveNoteAtIndex:(int)from toIndex:(int)to;

// Creates a new Tag
- (MMNTag *)createTag;

// Removes a Tag
- (void)removeTag:(MMNTag *)tag;

// Removes an array of tags. The array must contain MMNTag objects.
- (void)removeTags:(NSArray *)tags;

// Returns all Tags
- (NSArray *)allTags;

// Moves the Tag item in the list at specified position inthe GUI list
- (void)moveTagAtIndex:(int)from toIndex:(int)to;

// Checks whether there already exists another tag with same name.
// If so, the checkedTag is removed and the existing tag's order is set to the cjeckedTag's order.
// Usefull e.g. after a new tag has been added to make sure there is only 1 tag with the name and to
// "promote" the existing tag to the new sorting order.
// Case insensitive.
- (void)ensureUniqueTagName:(MMNTag *)checkedTag;

// Creates a new MMNAttachment of type MMNAttachmentTypeImage
- (MMNAttachment *)createAttachmentWithImage:(UIImage *)image;

// Removes the attachment and its associated file
- (void)removeAttachment:(MMNAttachment *)attachment;

- (BOOL)saveChanges;

- (void)loadAllData;



@end
