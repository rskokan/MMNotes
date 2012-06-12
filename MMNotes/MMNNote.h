//
//  MMNNote.h
//  MMNotes
//
//  Created by Radek Skokan on 5/30/12.
//  Copyright (c) 2012 radek@skokan.name. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class MMNAttachment, MMNTag;

// Maximum number of characters from the note body to be included in displayText if the note has no title
extern const int MMNNoteMaxDisplayTextLength;

@interface MMNNote : NSManagedObject

@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * body;
@property (nonatomic, retain) NSNumber * isFavorite; // Be carefull [[note isFavorite] boolValue] is needed!
@property (nonatomic, retain) NSDate * dateModified;
@property (nonatomic, retain) NSNumber * order;
@property (nonatomic, retain) NSSet *tags;
@property (nonatomic, retain) NSSet *attachments;

// A generated value. Normally set to the note's title. If title is empty, it contains 
// beginning of the note's body. If the body is empty, it contains the dateModified.
@property (nonatomic, readonly, strong) NSString *displayText;

// Returns true if the note has no title, no body and no attachments
- (BOOL)isEmpty;

// A convenience method that returns a sorted array of attachments of the MMNAttachmentTypeImage type
- (NSArray *)orderedImages;

// A convenience method that returns a set of attachments of the MMNAttachmentTypeImage type (should be faster than orderedImages).
- (NSSet *)images;

// Returns a string of tags that the note has ordered by their order attribute. E.g. [shopping, books]
- (NSString *)orderedTagsString;

@end

@interface MMNNote (CoreDataGeneratedAccessors)

- (void)addTagsObject:(MMNTag *)value;
- (void)removeTagsObject:(MMNTag *)value;
- (void)addTags:(NSSet *)values;
- (void)removeTags:(NSSet *)values;

- (void)addAttachmentsObject:(MMNAttachment *)value;
- (void)removeAttachmentsObject:(MMNAttachment *)value;
- (void)addAttachments:(NSSet *)values;
- (void)removeAttachments:(NSSet *)values;

@end
