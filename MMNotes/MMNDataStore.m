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

NSString * const MMNDataStoreUpdateNotification = @"MMNDataStoreUpdateNotification";

NSString * const DB_STORE_NAME = @"mmnotes_store.data";
NSString * const TRANS_LOG_NAME = @"mmnotes_trans.log";

@implementation MMNDataStore

+ (MMNDataStore *)sharedStore {
    static dispatch_once_t once;
    static MMNDataStore *sharedStore;
    
    dispatch_once(&once, ^{
        sharedStore = [[super allocWithZone:nil] init];
    });
    
    return sharedStore;
}

+ (id)allocWithZone:(NSZone *)zone {
    return [self sharedStore];
}

- (id)init {
    self = [super init];
    if (self) {
        dispatch_async (dispatch_get_global_queue (DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self openDB];
            [self reloadAllData];
            
            // Post a notification that content has been updated so that UI can be reloaded.
            // As the merge is running in background, we sent the notif. to the main app queue so there is no delay.
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                NSNotification *updateNotif = [NSNotification notificationWithName:MMNDataStoreUpdateNotification object:nil];
                [[NSNotificationCenter defaultCenter] postNotification:updateNotif];
            }];
        });
        
        // Register for iCloud notifications
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contentChange:)
                                                     name:NSPersistentStoreDidImportUbiquitousContentChangesNotification object:nil];
    }
    
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

// Merge iCloud content changes
- (void)contentChange:(NSNotification *)notif {
    NSLog(@"%@", NSStringFromSelector(_cmd));
    [ctx mergeChangesFromContextDidSaveNotification:notif];
    
    // Need to reload cached Notes and Tags: some might have been added or removed
    [self reloadAllData];
    
    // Post a notification that content has been updated so that UI can be reloaded.
    // As the merge is running in background, we sent the notif. to the main app queue so there is no delay.
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        NSNotification *updateNotif = [NSNotification notificationWithName:MMNDataStoreUpdateNotification object:nil];
        [[NSNotificationCenter defaultCenter] postNotification:updateNotif];
    }];
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

// Inits and opens DB. If the user has iCloud enabled, it will be used: the DB store file will be placed in the ubiquitous container, a .nosync folder. The transaction log wil be synchronized with iCloud.
// If iCloud is not available, the entire DB will be on the local file system.
- (void)openDB {
    // Read in MMNotes.xcdatamodeld
    model = [NSManagedObjectModel mergedModelFromBundles:nil];
    NSPersistentStoreCoordinator *psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
    
    // Find the location of the iCloud ubiquity container on the local file system
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *ubiContainer = [fileManager URLForUbiquityContainerIdentifier:nil]; // takes a long time
    NSURL *storeURL;
    NSError *error;
    
    if (ubiContainer) {
        NSLog(@"The user has iCloud, using it");
        storeURL = [self ubiquitousDBArchiveURL:ubiContainer];
        
        // Specify location of the transaction log in the ubiquity container
        NSMutableDictionary *options = [NSMutableDictionary dictionary];
        [options setObject:TRANS_LOG_NAME forKey:NSPersistentStoreUbiquitousContentNameKey];
        [options setObject:ubiContainer forKey:NSPersistentStoreUbiquitousContentURLKey];
        
        if (![psc addPersistentStoreWithType:NSSQLiteStoreType
                               configuration:nil
                                         URL:storeURL
                                     options:options
                                       error:&error]) {
            //            [NSException raise:@"DB open failed" format:@"Reason: %@", error];
            NSLog(@"Could not open database. Will try to remove old DB files and open again.");
            NSURL *transLogURL = [ubiContainer URLByAppendingPathComponent:TRANS_LOG_NAME];
            [self removeICloudDBStore:storeURL withTransLog:transLogURL];
            if (![psc addPersistentStoreWithType:NSSQLiteStoreType
                                   configuration:nil
                                             URL:storeURL
                                         options:nil
                                           error:&error]) {
                NSLog(@"DB opening failed again, exiting");
                [NSException raise:@"DB open failed" format:@"Reason: %@", error];
            }
        }
        
    } else {
        NSLog(@"iCloud is not available, using local file system");
        storeURL = [self localDBArchiveURL];
        
        if (![psc addPersistentStoreWithType:NSSQLiteStoreType
                               configuration:nil
                                         URL:storeURL
                                     options:nil
                                       error:&error]) {
            [NSException raise:@"DB open failed" format:@"Reason: %@", error];
        }
        
    }
    
    ctx = [[NSManagedObjectContext alloc] init];
    [ctx setPersistentStoreCoordinator:psc];
    [ctx setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
}

// Removes DB files (both data and transaction log) stored in iCloud
- (void)removeICloudDBStore:(NSURL *)storeURL withTransLog:(NSURL *)transLogURL {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    // Remove store
    NSError *error = nil;
    if ([fileManager fileExistsAtPath:[storeURL path]]) {
        NSLog(@"DB store file exists, removing");
        [fileManager removeItemAtURL:storeURL error:&error];
        if (error)
            NSLog(@"Error deleting old DB store");
    }
    
    // Remove transaction log
    error = nil;
    if ([fileManager fileExistsAtPath:[transLogURL path]]) {
        NSLog(@"DB transaction log exists, removing");
        [fileManager removeItemAtURL:transLogURL error:&error];
        if (error)
            NSLog(@"Error deleting old DB transaction log");
    }
}

// Returns the URL for the DB archive stored locally, NOT within the iCloud's ubiquitous container
- (NSURL *)localDBArchiveURL {
    NSArray *documentDirectories = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentDirectory = [documentDirectories objectAtIndex:0];
    NSString *storePath = [documentDirectory stringByAppendingPathComponent:DB_STORE_NAME];
    return [NSURL fileURLWithPath:storePath];
}

// Returns the URL for the DB archive stored within the iCloud's ubiquitous container
- (NSURL *)ubiquitousDBArchiveURL:(NSURL *)ubiquitousContainer {
    NSError *error;
    
    NSURL *nosyncUbiDir = [ubiquitousContainer URLByAppendingPathComponent:@"mmnotes.nosync"];
    if (![[NSFileManager defaultManager] createDirectoryAtURL:nosyncUbiDir
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:&error]) {
        NSLog(@"Error creating data directory in the ubiquitous container: %@", error);
    };
    
    return [nosyncUbiDir URLByAppendingPathComponent:DB_STORE_NAME];
}

- (BOOL)saveChanges {
    NSError *error;
    BOOL success = [ctx save:&error];
    
    if (!success) {
        NSLog(@"Error saving data: %@.\n Trying to re-open DB (perhaps iCloud was disabled)", error);
        // TODO: iOS 6 will have NSUbiquityIdentityDidChangeNotification to detect iCloud account changes
        [ctx reset];
        [self openDB];
        [ctx save:nil]; // It does not save here.
        
        [self reloadAllData];
        
        // Post a notification that content has been updated so that UI can be reloaded.
        NSNotification *updateNotif = [NSNotification notificationWithName:MMNDataStoreUpdateNotification object:nil];
        [[NSNotificationCenter defaultCenter] postNotification:updateNotif];
    }
    
    return success;
}

// Reloads all Notes and Tags
- (void)reloadAllData {
    allNotes = [[NSMutableArray alloc] initWithArray:[self fetchAllEntitiesWithName:@"MMNNote"]];
    
    allTags = [[NSMutableArray alloc] initWithArray:[self fetchAllEntitiesWithName:@"MMNTag"]];
}

- (NSArray *)fetchAllEntitiesWithName:(NSString *)name {
    NSFetchRequest *req = [[NSFetchRequest alloc] init];
    NSEntityDescription *ent = [[model entitiesByName] objectForKey:name];
    [req setEntity:ent];
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"order" ascending:YES];
    [req setSortDescriptors:[NSArray arrayWithObject:sort]];
    
    NSError *error;
    NSArray *res = [ctx executeFetchRequest:req error:&error];
    if (!res) {
        [NSException raise:@"Fetch failed" format:@"Entity: %@, reason: %@", name, error];
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
    
    [allTags insertObject:tag atIndex:0];
    return tag;
}

- (MMNAttachment *)createAttachmentWithImage:(UIImage *)image {
    UIImage *smallerImage = [self imageWithImage:image scaledToSize:CGSizeMake(1024.0, 768.0)];
    NSData *data = UIImageJPEGRepresentation(smallerImage, 0.6);
    MMNAttachment *att = [NSEntityDescription insertNewObjectForEntityForName:@"MMNAttachment" inManagedObjectContext:ctx];
    [att setAttachmentType:MMNAttachmentTypeImage];
    [att setData:data];
    
    return att;
}

- (void)removeAttachment:(MMNAttachment *)attachment
{ 
    [ctx deleteObject:attachment];
}

- (NSString *)attachmentPathForKey:(NSString *)key
{
    NSArray *documentDirectories = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentDirectory = [documentDirectories objectAtIndex:0];
    return [documentDirectory stringByAppendingPathComponent:key];
}

- (void)removeNote:(MMNNote *)note {
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
