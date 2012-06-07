//
//  MMNAttachment.m
//  MMNotes
//
//  Created by Radek Skokan on 5/30/12.
//  Copyright (c) 2012 radek@skokan.name. All rights reserved.
//

#import "MMNAttachment.h"


@implementation MMNAttachment

// Use the attachmentType which returns the MMNAttachmentType type. This is only for storing in DB.
@dynamic type;

@dynamic path;
@dynamic order;
@dynamic dateModified;

- (NSString *)description {
    return [NSString stringWithFormat:@"[MMNAttachment(type=%d, path=%@, order=%f]", [self type], [self path], [self order]];
}

// Returns the "type" attribute as MMNAttachmentType. It is stored in DB as NSNumber.
- (MMNAttachmentType)attachmentType {
    return (MMNAttachmentType) [[self type] intValue];
}

// Sets the "type" attribute. Then updates its internal representation, which is stored in DB as NSNumber.
- (void)setAttachmentType:(MMNAttachmentType)attachmentType {
    [self setType:[NSNumber numberWithInt:attachmentType]];
}

// To get KVO notifications for "attachmentType" when "type" changes
+ (NSSet *)keyPathsForValuesAffectingAttachmentType {
    return [NSSet setWithObject:@"type"];
}

@end
