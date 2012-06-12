//
//  MMNDataStore.m
//  MMNotes
//
//  Created by Radek Skokan on 5/30/12.
//  Copyright (c) 2012 radek@skokan.name. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "MMNDataStore.h"
#import "MMNNote.h"
#import "MMNTag.h"
#import "MMNAttachment.h"


@implementation MMNDataStore

+ (MMNDataStore *)sharedStore {
    static MMNDataStore * sharedStore = nil;
    
    if (!sharedStore) {
        sharedStore = [[super allocWithZone:nil] init];
    }
    
    return sharedStore;
}

+ (id)allocWithZone:(NSZone *)zone {
    return [self sharedStore];
}

- (id)init {
    self = [super init];
    if (self) {
        // Read in MMNotes.xcdatamodeld
        model = [NSManagedObjectModel mergedModelFromBundles:nil];
        NSPersistentStoreCoordinator *psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
        
        NSURL *storeURL = [NSURL fileURLWithPath:[self dbArchivePath]];
        NSError *error = nil;
        
        if (![psc addPersistentStoreWithType:NSSQLiteStoreType
                               configuration:nil
                                         URL:storeURL
                                     options:nil
                                       error:&error]) {
            [NSException raise:@"DB open failed" format:@"Reason: %@", [error localizedDescription]];
        }
        
        ctx = [[NSManagedObjectContext alloc] init];
        [ctx setPersistentStoreCoordinator:psc];
        [ctx setUndoManager:nil];
        
        [self loadAllData];
    }
    
    return self;
}

- (UIImage*)imageWithImage:(UIImage*)image 
              scaledToSize:(CGSize)newSize {
    CGSize origSize = [image size];
    
    if (origSize.width < origSize.height && newSize.width > newSize.height) {
        NSLog(@"Adopting newSize to the image, exchanging width and height");
        CGFloat tmp = newSize.width;
        newSize.width = newSize.height;
        newSize.height = tmp;
    }
    
    CGFloat ratio = newSize.width / origSize.width;
    newSize.height = origSize.height * ratio;
    NSLog(@"The new image size will be %1.0f x %1.0f to maintain aspect ratio", newSize.width, newSize.height); 
    
    UIGraphicsBeginImageContext(newSize);
    [image drawInRect:CGRectMake(0.0, 0.0 ,newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    NSLog(@"Original image of size %1.0f x %1.0f scaled to %1.0f x %1.0f", [image size].width, [image size].height, [newImage size].width, [newImage size].height);
    
    return newImage;
}

- (NSString *)dbArchivePath {
    NSArray *documentDirectories = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentDirectory = [documentDirectories objectAtIndex:0];
    return [documentDirectory stringByAppendingPathComponent:@"store.data"];
}


- (BOOL)saveChanges {
    NSError *err;
    BOOL success = [ctx save:&err];
    if (!success) {
        NSLog(@"Error saving data: %@", [err localizedDescription]);
    }
    
    return success;
}

// Loads all Notes and Tags from DB if not already loaded
- (void)loadAllData {
    if (!allNotes)
        allNotes = [[NSMutableArray alloc] initWithArray:[self fetchAllEntitiesWithName:@"MMNNote"]];
    
    if (!allTags)
        allTags = [[NSMutableArray alloc] initWithArray:[self fetchAllEntitiesWithName:@"MMNTag"]];
}

- (NSArray *)fetchAllEntitiesWithName:(NSString *)name {
    NSFetchRequest *req = [[NSFetchRequest alloc] init];
    NSEntityDescription *ent = [[model entitiesByName] objectForKey:name];
    [req setEntity:ent];
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"order" ascending:YES];
    [req setSortDescriptors:[NSArray arrayWithObject:sort]];
    
    NSError *err;
    NSArray *res = [ctx executeFetchRequest:req error:&err];
    if (!res) {
        [NSException raise:@"Fetch failed" format:@"Entity: %@, reason: %@", name, [err localizedDescription]];
    }
    
    return res;
}

- (NSArray *)allNotes {
    return allNotes;
}

- (NSArray *)favoritedNotes {
    static NSPredicate *favoriteNotesPredicate = nil;
    if (!favoriteNotesPredicate) {
        favoriteNotesPredicate = [NSPredicate predicateWithFormat:@"isFavorite == TRUE"];
    }
    
    return [allNotes filteredArrayUsingPredicate:favoriteNotesPredicate];
}

- (NSArray *)notesTaggedWith:(MMNTag *)aTag {
    NSPredicate *notesWithTagPredicate = [NSPredicate predicateWithFormat:@"%@ IN SELF.tags", aTag];
    return [allNotes filteredArrayUsingPredicate:notesWithTagPredicate];
}

- (NSArray *)allTags {
    return allTags;
}

- (MMNNote *)createNote {
    double order;
    if ([allNotes count] == 0) {
        order = 1.0;
    } else {
        // Insert as the first item
        order = [[[allNotes objectAtIndex:0] order] doubleValue] - 1.0;
    }
    NSLog(@"New note, adding before %d notes, order = %.2f", [allNotes count], order);
    
    MMNNote *note = [NSEntityDescription insertNewObjectForEntityForName:@"MMNNote"
                                                  inManagedObjectContext:ctx];
    [note setOrder:[NSNumber numberWithDouble:order]];
    [note setDateModified:[NSDate date]];
    
    [allNotes insertObject:note atIndex:0];
    return note;
}

- (MMNTag *)createTag {
    double order;
    if ([allTags count] == 0) {
        order = 1.0;
    } else {
        // Insert as the first item
        order = [[[allTags objectAtIndex:0] order] doubleValue] - 1.0;
    }
    NSLog(@"New tag, adding before %d tags, order = %.2f", [allTags count], order);
    
    MMNTag *tag = [NSEntityDescription insertNewObjectForEntityForName:@"MMNTag"
                                                inManagedObjectContext:ctx];
    [tag setOrder:[NSNumber numberWithDouble:order]];
    [tag setDateModified:[NSDate date]];
    
    [allTags insertObject:tag atIndex:0];
    return tag;
}

- (MMNAttachment *)createAttachmentWithImage:(UIImage *)image {
    CFUUIDRef imageIdRef = CFUUIDCreate(kCFAllocatorDefault);
    CFStringRef imageIdStrRef = CFUUIDCreateString(kCFAllocatorDefault, imageIdRef);
    NSString *imageId = (__bridge NSString *) imageIdStrRef;
    NSString *path = [self attachmentPathForKey:[NSString stringWithFormat:@"%@.jpg", imageId]];
    UIImage *smallerImage = [self imageWithImage:image scaledToSize:CGSizeMake(1024.0, 768.0)];
    NSData *data = UIImageJPEGRepresentation(smallerImage, 0.6);
    // TODO: downscale the attachment
    if ([data writeToFile:path atomically:YES]) {
        NSLog(@"Image file written at %@, size: %d B", path, [data length]);
    } else {
        NSLog(@"Error writing image file to %@", path);
    }
    CFRelease(imageIdRef);
    CFRelease(imageIdStrRef);
    
    
    MMNAttachment *att = [NSEntityDescription insertNewObjectForEntityForName:@"MMNAttachment" inManagedObjectContext:ctx];
    [att setAttachmentType:MMNAttachmentTypeImage];
    [att setDateModified:[NSDate date]];
    [att setPath:path];
    
    return att;
}

- (void)removeAttachment:(MMNAttachment *)attachment
{
//    The file is deleted in MMNAttachment.prepareForDeletion
//    if ([attachment path]) {
//        [[NSFileManager defaultManager] removeItemAtPath:[attachment path] error:NULL];
//        NSLog(@"Deleted attachment file %@", [attachment path]);
//    }
    
    [ctx deleteObject:attachment];
}

- (NSString *)attachmentPathForKey:(NSString *)key
{
    NSArray *documentDirectories = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentDirectory = [documentDirectories objectAtIndex:0];
    return [documentDirectory stringByAppendingPathComponent:key];
}

- (void)removeNote:(MMNNote *)note {
    // TODO: Remove all associated attachments
    [ctx deleteObject:note];
    [allNotes removeObjectIdenticalTo:note];
}

- (void)removeTag:(MMNTag *)tag {
    [ctx deleteObject:tag];
    [allTags removeObjectIdenticalTo:tag];
}

- (void)removeTags:(NSArray *)tags {
    for (MMNTag *tag in tags) {
        [self removeTag:tag];
    }
}

// TODO: eliminate copy pastes in similar Notes and Tags methods...
- (void)moveNoteAtIndex:(int)from toIndex:(int)to {
    if (from == to) {
        return;
    }
    
    MMNNote *note = [allNotes objectAtIndex:from];
    [allNotes removeObjectAtIndex:from];
    [allNotes insertObject:note atIndex:to];
    
    double lowerBound = 0.0;
    // Is there an object before it in the array?
    if (to > 0) {
        lowerBound = [[[allNotes objectAtIndex:to - 1] order] doubleValue];
    } else {
        lowerBound = [[[allNotes objectAtIndex:1] order]  doubleValue] - 2.0;
    }
    
    double upperBound = 0.0;
    // Is there an object after in the array?
    if (to < [allNotes count] - 1) {
        upperBound = [[[allNotes objectAtIndex:to + 1] order]  doubleValue];
    } else {
        upperBound = [[[allNotes objectAtIndex:to - 1] order]  doubleValue] + 2.0;
    }
    
    double newOrderValue = (lowerBound + upperBound) / 2.0;
    
    NSLog(@"Moving note to order %f", newOrderValue);
    [note setOrder:[NSNumber numberWithDouble:newOrderValue]];
}

// TODO: eliminate copy pastes in similar Notes and Tags methods...
- (void)moveTagAtIndex:(int)from toIndex:(int)to {
    if (from == to) {
        return;
    }
    
    MMNTag *tag = [allTags objectAtIndex:from];
    [allTags removeObjectAtIndex:from];
    [allTags insertObject:tag atIndex:to];
    
    double lowerBound = 0.0;
    // Is there an object before it in the array?
    if (to > 0) {
        lowerBound = [[[allTags objectAtIndex:to - 1] order] doubleValue];
    } else {
        lowerBound = [[[allTags objectAtIndex:1] order]  doubleValue] - 2.0;
    }
    
    double upperBound = 0.0;
    // Is there an object after in the array?
    if (to < [allTags count] - 1) {
        upperBound = [[[allTags objectAtIndex:to + 1] order]  doubleValue];
    } else {
        upperBound = [[[allTags objectAtIndex:to - 1] order]  doubleValue] + 2.0;
    }
    
    double newOrderValue = (lowerBound + upperBound) / 2.0;
    
    NSLog(@"Moving tag to order %f", newOrderValue);
    [tag setOrder:[NSNumber numberWithDouble:newOrderValue]];
}

- (void)ensureUniqueTagName:(MMNTag *)checkedTag {
    NSString *checkedName = [checkedTag name];
    for (MMNTag *otherTag in allTags) {
        NSString *otherName = [otherTag name];
        if ([[checkedName lowercaseString] isEqualToString:[otherName lowercaseString]] && checkedTag != otherTag) {
            NSLog(@"Found older tag with same name: %@; removing new tag", otherTag);
            [otherTag setOrder:[checkedTag order]];
            [allTags removeObject:otherTag];
            [allTags insertObject:otherTag atIndex:[allTags indexOfObject:checkedTag]];
            [self removeTag:checkedTag];
            break;
        }
    }
}


@end
