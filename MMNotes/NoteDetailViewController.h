//
//  NoteDetailViewController.h
//  MMNotes
//
//  Created by Radek Skokan on 5/30/12.
//  Copyright (c) 2012 radek@skokan.name. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MMNNote;

@interface NoteDetailViewController : UIViewController <UITextFieldDelegate, UIAlertViewDelegate>
{
    
    __weak IBOutlet UITextField *titleField;
    __weak IBOutlet UITextView *bodyField;
    __weak IBOutlet UIButton *tagsButton;
    
    // The bar buttom to toggle and indicate in the note detail view whether the note is a favorite
    UIBarButtonItem *favoriteItem;
    
    // The bar buttom to indicate in the note detail view whether the note has a photo attachment
    UIBarButtonItem *photoItem;
    
    // The bar buttom to indicate in the note detail view whether the note has an audio attachment
    UIBarButtonItem *audioItem;
    
    // Just to be sure (memory), I'm accessing the _note directly in its setter
    MMNNote *_note;
}

@property (nonatomic, strong) MMNNote *note;
@property (nonatomic, readonly) BOOL isNew;
@property (nonatomic, copy) void (^dismissBlock)(void);

// The designated initializer.
// isNew specifies whether the Note is being newly created and does not exist yet.
- (id)initForNewNote:(BOOL)isNew;

- (IBAction)showTagsPicker:(id)sender;

// When the "background" is tapped, hide the keyboard
- (IBAction)backgroundTapped:(id)sender;

// Change in the note title field, update the view title
- (IBAction)titleFieldChanged:(id)sender;

@end
