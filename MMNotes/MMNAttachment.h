//
//  MMNAttachment.h
//  MMNotes
//
//  Created by Radek Skokan on 5/30/12.
//  Copyright (c) 2012 radek@skokan.name. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

typedef enum {
    MMNAttachmentTypeImage = 0,
    MMNAttachmentTypeAudio = 1
} MMNAttachmentType;

// Represents a noe attachment, typically a photo or audio.
// It is owned by a MMNNote object. If the note is removed, all its MMNAttachments are also removed (cascade delete).
// Therefor make sure that when an attachment is deleted, the relevant file is also deleted!
//
@interface MMNAttachment : NSManagedObject

// Use the attachmentType which returns the MMNAttachmentType type. This is only for storing in DB.
@property (nonatomic, retain) NSNumber * type;
@property (nonatomic) MMNAttachmentType attachmentType;

@property (nonatomic, retain) NSString * path;
@property (nonatomic, retain) NSNumber * order;
@property (nonatomic, retain) NSDate * dateModified;

// To get KVO notifications for "attachmentType" when "type" changes
+ (NSSet *)keyPathsForValuesAffectingAttachmentType;

@end
