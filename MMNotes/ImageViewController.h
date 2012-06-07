//
//  ImageViewController.h
//  MMNotes
//
//  Created by Radek Skokan on 6/6/12.
//  Copyright (c) 2012 radek@skokan.name. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MMNAttachment;

@interface ImageViewController : UIViewController
{
    __weak IBOutlet UIImageView *imageView;
    __weak IBOutlet UILabel *dateLabel;
}

@property (nonatomic, readonly, strong) MMNAttachment *imageAttachment;

- (id)initWithImage:(MMNAttachment *)imageAttachment;

@end
