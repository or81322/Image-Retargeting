//
//  AspectRatioPickerTableViewController.h
//  Image Resizing
//
//  Created by or maayan on 10/9/14.
//  Copyright (c) 2014 Or Maayan & Micheal Leybovich. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol AspectRatioPickerDelegate
- (void)setAspectRatio:(double)aspectRatio;
- (void)didFinishChoosingAspectRatio:(id)sender;
@end

@protocol AspectRatioPickerDataSource
- (double)sourceAspectRatio;
@end

@interface AspectRatioPickerTableViewController : UITableViewController
@property (nonatomic, weak) id <AspectRatioPickerDelegate> delegate;
@property (nonatomic, weak) id <AspectRatioPickerDataSource> dataSource;

- (id)initWithStyle:(UITableViewStyle)style andDataSource:(id)dataSource andDelegate:(id)delegate;

@end
