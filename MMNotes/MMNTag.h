//
//  MMNTag.h
//  MMNotes
//
//  Created by Radek Skokan on 5/30/12.
//  Copyright (c) 2012 radek@skokan.name. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class MMNNote;

@interface MMNTag : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSDate * dateModified;
@property (nonatomic, retain) NSNumber * order;
@property (nonatomic, retain) NSSet *notes;
@end

@interface MMNTag (CoreDataGeneratedAccessors)

- (void)addNotesObject:(MMNNote *)value;
- (void)removeNotesObject:(MMNNote *)value;
- (void)addNotes:(NSSet *)values;
- (void)removeNotes:(NSSet *)values;

@end
