//
//  AspectRatioPickerTableViewController.m
//  Image Resizing
//
//  Created by or maayan on 10/9/14.
//  Copyright (c) 2014 Or Maayan & Micheal Leybovich. All rights reserved.
//

#import "AspectRatioPickerTableViewController.h"

@interface AspectRatioPickerTableViewController ()

@end

@implementation AspectRatioPickerTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (id)initWithStyle:(UITableViewStyle)style andDataSource:(id)dataSource andDelegate:(id)delegate
{
    self = [self initWithStyle:style];
    self.dataSource = dataSource;
    self.delegate = delegate;
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.title = @"Choose Aspect Ratio";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self.delegate action:@selector(didFinishChoosingAspectRatio:)];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case 0:
            return 8;
        case 1:
            return 1;
        case 2:
            return 4;
        default:
            return 0;
            break;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if(section==0) return @"Classical Aspect Ratios";
    if(section==1) return @"Original Aspect Ratio";
    if(section==2) return @"RetargetMe Ratios";
    return @"";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell;
    // Configure the cell...
    if(cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    
    if(indexPath.section == 0) {
        if(indexPath.row == 0) cell.textLabel.text = @"1:1         squared";
        if(indexPath.row == 1) cell.textLabel.text = @"4:3         landscape";
        if(indexPath.row == 2) cell.textLabel.text = @"3:4         portrait";
        if(indexPath.row == 3) cell.textLabel.text = @"16:9       widescreen";
        if(indexPath.row == 4) cell.textLabel.text = @"2.39:1    cinema";
        if(indexPath.row == 5) cell.textLabel.text = @"3:2         classic 35mm film";
        if(indexPath.row == 6) cell.textLabel.text = @"2:3         iPhone";
        if(indexPath.row == 7) cell.textLabel.text = @"1.618:1  golden ratio";
    }
    if(indexPath.section==1) {
        cell.textLabel.text = @"back to original aspect ratio";
    }
    if(indexPath.section==2) {
        if(indexPath.row == 0) cell.textLabel.text = @"0.5         width";
        if(indexPath.row == 1) cell.textLabel.text = @"0.75       width";
        if(indexPath.row == 2) cell.textLabel.text = @"1.25       width";
        if(indexPath.row == 3) cell.textLabel.text = @"0.75       height";
    }
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    double targetAspectRatio = 1.0;
    if (indexPath.section == 0) {
        if(indexPath.row == 0) targetAspectRatio = 1.0;
        if(indexPath.row == 1) targetAspectRatio = 4.0 / 3.0;
        if(indexPath.row == 2) targetAspectRatio = 3.0 / 4.0;
        if(indexPath.row == 3) targetAspectRatio = 16.0 / 9.0;
        if(indexPath.row == 4) targetAspectRatio = 2.39;
        if(indexPath.row == 5) targetAspectRatio = 3.0 / 2.0;
        if(indexPath.row == 6) targetAspectRatio = 2.0 / 3.0;
        if(indexPath.row == 7) targetAspectRatio = 1.618;
    }
    
    if (indexPath.section == 1) {
        targetAspectRatio = [self.dataSource sourceAspectRatio];
    }
    
    if (indexPath.section == 2) {
        if(indexPath.row == 0) targetAspectRatio = 0.50 * [self.dataSource sourceAspectRatio];
        if(indexPath.row == 1) targetAspectRatio = 0.75 * [self.dataSource sourceAspectRatio];
        if(indexPath.row == 2) targetAspectRatio = 1.25 * [self.dataSource sourceAspectRatio];
        if(indexPath.row == 3) targetAspectRatio = [self.dataSource sourceAspectRatio] / 0.75;
    }
    
    [self.delegate setAspectRatio:targetAspectRatio];
    [self.delegate didFinishChoosingAspectRatio:self];
}

@end

