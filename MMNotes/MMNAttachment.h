//
//  MMNAttachment.h
//  MMNotes
//
//  Created by Radek Skokan on 5/30/12.
//  Copyright (c) 2012 radek@skokan.name. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

// Represents a noe attachment, typically a photo or audio.
// It is owned by a MMNNote object. If the note is removed, all its MMNAttachments are also removed (cascade delete).
// Therefor make sure that when an attachment is deleted, the relevant file is also deleted!
//
@interface MMNAttachment : NSManagedObject

@property (nonatomic, retain) NSNumber * type;
@property (nonatomic, retain) NSString * locationURL;
@property (nonatomic, retain) NSNumber * order;

@end
