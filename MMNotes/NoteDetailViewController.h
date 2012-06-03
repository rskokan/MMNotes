//
//  NoteDetailViewController.h
//  MMNotes
//
//  Created by Radek Skokan on 5/30/12.
//  Copyright (c) 2012 radek@skokan.name. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MMNNote;

@interface NoteDetailViewController : UIViewController <UITextFieldDelegate>
{
    
    __weak IBOutlet UITextField *titleField;
    __weak IBOutlet UITextView *bodyField;
    __weak IBOutlet UIButton *tagsButton;
}

@property (nonatomic, strong) MMNNote *note;
@property (nonatomic, copy) void (^dismissBlock)(void);

// The designated initializer.
// isNew specifies whether the Note is being newly created and does not exist yet.
- (id)initForNewNote:(BOOL)isNew;

- (IBAction)showTagsPicker:(id)sender;

@end
