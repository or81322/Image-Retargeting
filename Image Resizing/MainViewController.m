//
//  MainViewController.m
//  Image Resizing
//
//  Created by Or Maayan on 8/10/14.
//  Copyright (c) 2014 Or Maayan & Micheal Leybovich. All rights reserved.
//

#import "MainViewController.h"

@interface MainViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate>
@property (strong, nonatomic) UIPopoverController *imagePickerPopover;
@property (strong, nonatomic) UIImagePickerController *imagePickerController;
@property (strong, nonatomic) UIImage *image;
@end

@implementation MainViewController

#define IDIOM    UI_USER_INTERFACE_IDIOM()
#define IPAD     UIUserInterfaceIdiomPad
#define IPHONE   UIUserInterfaceIdiomPhone

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Properties

-(UIImagePickerController *)imagePickerController {
    if (_imagePickerController == nil) {
        _imagePickerController = [[UIImagePickerController alloc] init];
        _imagePickerController.delegate = self;
        _imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    }
    return _imagePickerController;
}

-(UIPopoverController *)imagePickerPopover {
    if (_imagePickerPopover == nil) {
        _imagePickerPopover = [[UIPopoverController alloc] initWithContentViewController:self.imagePickerController];
    }
    return _imagePickerPopover;
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"Show Image"]) {
        if ([segue.destinationViewController respondsToSelector:@selector(setImage:)]) {
            [segue.destinationViewController performSelector:@selector(setImage:) withObject:self.image];
        }
    }
}

-(BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    if ([identifier isEqualToString:@"Show Image"]) {
        return (!self.imagePickerPopover.popoverVisible) ? YES : NO;
    } else {
        return [super shouldPerformSegueWithIdentifier:identifier sender:sender];
    }
}

#pragma mark - IBActions

- (IBAction)pickImage:(id)sender {
    UIButton *button = (UIButton *)sender;
    if (IDIOM == IPAD) {
        [self.imagePickerPopover presentPopoverFromRect:button.frame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    } else {
        [self presentViewController:self.imagePickerController animated:YES completion:nil];
    }
}

#pragma mark - UIImagePickerController

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    NSLog(@"finished picking");
    
    [self dismissImagePickerController];
    
    UIImage *image = [info valueForKey:UIImagePickerControllerOriginalImage];
    if (image) {
        self.image = image;
    } else {
        // error
    }
    
    // TODO
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    NSLog(@"canceled picking");
    
    [self dismissImagePickerController];
    
    // TODO
}

#pragma mark - private methods

-(void)dismissImagePickerController {
    if (IDIOM == IPAD) {
        [self.imagePickerPopover dismissPopoverAnimated:YES];
    } else {
        [self.imagePickerController dismissViewControllerAnimated:YES completion:nil];
    }
}






@end
