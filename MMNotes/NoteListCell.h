//
//  NoteListCell.h
//  MMNotes
//
//  Created by Radek Skokan on 6/8/12.
//  Copyright (c) 2012 radek@skokan.name. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MMNNote;

@interface NoteListCell : UITableViewCell
{
    
    __weak IBOutlet UILabel *titleLabel;
    __weak IBOutlet UILabel *tagsLabel;
    
    __weak IBOutlet UIButton *starButton;
    __weak IBOutlet UIButton *photoButton;
    __weak IBOutlet UIButton *micButton;
}

@property (nonatomic, strong) MMNNote *note;

@end
