//
//  MainViewController.m
//  Image Resizing
//
//  Created by Or Maayan on 8/10/14.
//  Copyright (c) 2014 Or Maayan & Micheal Leybovich. All rights reserved.
//

#import "MainViewController.h"
#import "UIImage+FixOrientation.h"
#import "AspectRatioPickerTableViewController.h"
#import "Algorithm.h"

@interface MainViewController () < UINavigationControllerDelegate , UIImagePickerControllerDelegate , AspectRatioPickerDataSource , AspectRatioPickerDelegate >
@property (strong, nonatomic) UIPopoverController *imagePickerPopover;
@property (strong, nonatomic) UIImagePickerController *imagePickerController;

@property (strong, nonatomic) AspectRatioPickerTableViewController *aspectRatioPickerController;
@property (strong, nonatomic) UIPopoverController *aspectRatioPickerPopover;

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
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
    self.image = self.imageView.image;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)updateImageViewWithImage:(UIImage *)image{
    if (self.imageView) {
        if (image) {
            self.imageView.image = image;
        }
    }
}

#pragma mark - Properties

-(UIImagePickerController *)imagePickerController {
    if (_imagePickerController == nil) {
        _imagePickerController = [[UIImagePickerController alloc] init];
        _imagePickerController.delegate = self;
        _imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        //_imagePickerController.allowsEditing = YES;
    }
    return _imagePickerController;
}

-(UIPopoverController *)imagePickerPopover {
    if (_imagePickerPopover == nil && IDIOM == IPAD) {
        _imagePickerPopover = [[UIPopoverController alloc] initWithContentViewController:self.imagePickerController];
    }
    return _imagePickerPopover;
}

-(UITableViewController *)aspectRatioPickerController {
    if (_aspectRatioPickerController == nil) {
        _aspectRatioPickerController = [[AspectRatioPickerTableViewController alloc] initWithStyle:UITableViewStyleGrouped andDataSource:self andDelegate:self];
    }
    return _aspectRatioPickerController;
}

-(UIPopoverController *)aspectRatioPickerPopover {
    if (_aspectRatioPickerPopover == nil && IDIOM == IPAD) {
        _aspectRatioPickerPopover = [[UIPopoverController alloc] initWithContentViewController:self.aspectRatioPickerController];
    }
    return _aspectRatioPickerPopover;
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
    //UIButton *button = (UIButton *)sender;
    if (IDIOM == IPAD) {
        //[self.imagePickerPopover presentPopoverFromRect:button.frame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
        
        UIBarButtonItem *button = (UIBarButtonItem *)sender;
        [self.imagePickerPopover presentPopoverFromBarButtonItem:button permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    } else {
        [self presentViewController:self.imagePickerController animated:YES completion:nil];
    }
}

- (IBAction)aspectRatioMenu:(id)sender {
    if (IDIOM == IPAD) {
        UIBarButtonItem *button = (UIBarButtonItem *)sender;
        [self.aspectRatioPickerPopover presentPopoverFromBarButtonItem:button permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    } else {
        [self presentViewController:self.aspectRatioPickerController animated:YES completion:nil];
    }
}

#pragma mark - UIImagePickerController

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    NSLog(@"finished picking");
    
    [self dismissImagePickerController];
    
    UIImage *image = [info valueForKey:UIImagePickerControllerOriginalImage];
    if (image) {
        self.image = [image fixOrientation];
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

#pragma mark - AspectRatioPickerDelegate

-(void)setAspectRatio:(double)aspectRatio {
    if (self.image) {
        
        // assert that it is within 1/10 to 10/1 of the original ratio
        #define RESIZE_FACTOR 10
        double targetAspectRatio = aspectRatio;
        targetAspectRatio = MIN(targetAspectRatio, RESIZE_FACTOR * self.sourceAspectRatio);
        targetAspectRatio = MAX(targetAspectRatio, 1.0 / RESIZE_FACTOR * self.sourceAspectRatio);
        
        // calculate targetImageSize
        CGFloat targetimageWidth = self.image.size.width , targetImageHeight = self.image.size.height;
        double aspectRatioFactor = targetAspectRatio / self.sourceAspectRatio;
        if (aspectRatioFactor > 1) {
            targetimageWidth *= aspectRatioFactor;
        } else {
            targetImageHeight /= aspectRatioFactor;
        }
        
        CGSize targetImageSize = CGSizeMake(targetimageWidth, targetImageHeight);
        
        // should support retargeting with saliency image
        UIImage *modifiedImage = [[[Algorithm alloc] initWithTargetImageSize:targetImageSize] autoRetargeting:self.image];
        [self updateImageViewWithImage:modifiedImage];
    }
    
    // TODO
    // run the algorithm on different thread
    // maybe should keep the aspect ratio selection
}

-(void)didFinishChoosingAspectRatio:(id)sender {
    [self.aspectRatioPickerController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - AspectRatioPickerDataSource

-(double)sourceAspectRatio {
    return self.image.size.width / self.image.size.height;
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
