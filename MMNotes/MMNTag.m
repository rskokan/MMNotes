//
//  MMNTag.m
//  MMNotes
//
//  Created by Radek Skokan on 5/30/12.
//  Copyright (c) 2012 radek@skokan.name. All rights reserved.
//

#import "MMNTag.h"
#import "MMNNote.h"


@implementation MMNTag

@dynamic name;
@dynamic dateModified;
@dynamic order;
@dynamic notes;

- (NSString *)description {
    return [NSString stringWithFormat:@"[MMNTag(name=%@, dateModified=%@, order=%f]", [self name], [self dateModified], [self order]];
}

- (void)willSave {
    // Update dateModified only when it has not been already updated
    if (([[self changedValues] count] > 0) && (! [self isDeleted])
        && (! [[[self changedValues] allKeys] containsObject:@"dateModified"])) {
        NSLog(@"MMNTag.willSave: updating dateModified; changedValues: %@", [self changedValues]);
        [self setDateModified:[NSDate date]];
    }
}

@end
