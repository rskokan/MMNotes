//
//  MMNAttachment.m
//  MMNotes
//
//  Created by Radek Skokan on 5/30/12.
//  Copyright (c) 2012 radek@skokan.name. All rights reserved.
//

#import "MMNAttachment.h"


@implementation MMNAttachment

@dynamic type;
@dynamic locationURL;
@dynamic order;

- (NSString *)description {
    return [NSString stringWithFormat:@"[MMNAttachment(type=%d, locationURL=%@, order=%f]", [self type], [self locationURL], [self order]];
}

@end
