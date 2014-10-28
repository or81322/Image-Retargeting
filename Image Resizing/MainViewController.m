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
#import "UIImage+Alpha.h"
#import <AVFoundation/AVFoundation.h>


@interface MainViewController () < UINavigationControllerDelegate , UIImagePickerControllerDelegate , AspectRatioPickerDataSource , AspectRatioPickerDelegate >
@property (strong, nonatomic) UIPopoverController *imagePickerPopover;
@property (strong, nonatomic) UIImagePickerController *imagePickerController;

@property (strong, nonatomic) AspectRatioPickerTableViewController *aspectRatioPickerController;
@property (strong, nonatomic) UIPopoverController *aspectRatioPickerPopover;

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) UIImage *image;
@property (weak, nonatomic) IBOutlet UIImageView *saliencyImageView;

@property (nonatomic) BOOL isShowingSaliency;

@property (nonatomic) CGRect originalImageViewFrame;

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
    
    self.originalImageViewFrame = self.imageView.frame;
    [self.imageView.layer setBorderColor: [[UIColor whiteColor] CGColor]];
    [self.imageView.layer setBorderWidth: 6.0];
    [self.imageView setFrame:AVMakeRectWithAspectRatioInsideRect(self.imageView.image.size, self.saliencyImageView.frame)];
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
            [self.imageView setFrame:AVMakeRectWithAspectRatioInsideRect(self.imageView.image.size, self.saliencyImageView.frame)];
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
        if (self.isShowingSaliency)
            [self toggleSaliency];
        [self updateImageViewWithImage:self.image];
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
        
        if (self.isShowingSaliency)
            [self toggleSaliency];
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

#pragma mark - saliency related

- (void)toggleSaliency {
    if (self.isShowingSaliency) {
        //[self updateImageViewWithImage:self.image];
        self.saliencyImageView.image = nil;
    }
    else {
        UIImage *saliencyImage = [[[Algorithm alloc] init] saliencyFromImage:self.image];
        UIImage *maskedImage = [self maskImage:saliencyImage withMask:self.image];
        //[self updateImageViewWithImage:maskedImage];
        
        //saliencyImage = [self changeColorToTransparent:saliencyImage];
        maskedImage = [self maskImage2:saliencyImage withMask:self.image];
        
        self.saliencyImageView.image = maskedImage;
        [self updateImageViewWithImage:self.image];
        //self.imageView.image = nil;
        
    }
    self.isShowingSaliency = !self.isShowingSaliency;
}

- (IBAction)toggleSaliency:(id)sender {
    [self toggleSaliency];
}

- (UIImage *)maskImage2:(UIImage *)image withMask:(UIImage *)mask
{
    CGImageRef imageReference = image.CGImage;
    UIImage *maskWithAlpha = [mask imageByApplyingAlpha:0.8];
    
    CGImageRef maskReference = maskWithAlpha.CGImage;
    
    CGImageRef imageMask = CGImageMaskCreate(CGImageGetWidth(maskReference),
                                             CGImageGetHeight(maskReference),
                                             CGImageGetBitsPerComponent(maskReference),
                                             CGImageGetBitsPerPixel(maskReference),
                                             CGImageGetBytesPerRow(maskReference),
                                             CGImageGetDataProvider(maskReference),
                                             NULL, // Decode is null
                                             YES // Should interpolate
                                             );
    
    UIImage *maskImage = [UIImage imageWithCGImage:imageMask];
    CGImageRef maskedReference = CGImageCreateWithMask(imageReference, imageMask);
    //CGImageRef maskedReference = CGImageCreateWithMask(imageReference, maskReference);
    CGImageRelease(imageMask);
    
    UIImage *maskedImage = [UIImage imageWithCGImage:maskedReference];
    CGImageRelease(maskedReference);
    
    return maskedImage;
    //return maskImage;
}


- (UIImage *)maskImage:(UIImage *)image withMask:(UIImage *)mask
{
    CGImageRef imageReference = image.CGImage;
    UIImage *maskWithAlpha = [mask imageByApplyingAlpha:0.6];
    
    CGImageRef maskReference = maskWithAlpha.CGImage;
    
    CGImageRef imageMask = CGImageMaskCreate(CGImageGetWidth(maskReference),
                                             CGImageGetHeight(maskReference),
                                             CGImageGetBitsPerComponent(maskReference),
                                             CGImageGetBitsPerPixel(maskReference),
                                             CGImageGetBytesPerRow(maskReference),
                                             CGImageGetDataProvider(maskReference),
                                             NULL, // Decode is null
                                             YES // Should interpolate
                                             );
    
    UIImage *maskImage = [UIImage imageWithCGImage:imageMask];
    CGImageRef maskedReference = CGImageCreateWithMask(imageReference, imageMask);
    CGImageRelease(imageMask);
    
    UIImage *maskedImage = [UIImage imageWithCGImage:maskedReference];
    CGImageRelease(maskedReference);
    
    //return maskedImage;
    return maskImage;
}

-(UIImage *)changeColorToTransparent: (UIImage *)image{
    CGImageRef rawImageRef = image.CGImage;
    const CGFloat colorMasking[6] = { 0, 50, 0, 50, 0, 50 };
    UIGraphicsBeginImageContext(image.size);
    CGImageRef maskedImageRef =  CGImageCreateWithMaskingColors(rawImageRef, colorMasking);
    {
        CGContextTranslateCTM(UIGraphicsGetCurrentContext(), 0.0, image.size.height);
        CGContextScaleCTM(UIGraphicsGetCurrentContext(), 1.0, -1.0);
    }
    
    CGContextDrawImage(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, image.size.width, image.size.height), maskedImageRef);
    UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
    CGImageRelease(maskedImageRef);
    UIGraphicsEndImageContext();
    return result;
}

-(UIImage *)changeWhiteColorTransparent: (UIImage *)image
{
    CGImageRef rawImageRef=image.CGImage;
    
    const CGFloat colorMasking[6] = {0, 1, 0, 1, 0, 1};
    
    UIGraphicsBeginImageContext(image.size);
    CGImageRef maskedImageRef = CGImageCreateWithMaskingColors(rawImageRef, colorMasking);
    {
        //if in iphone
        CGContextTranslateCTM(UIGraphicsGetCurrentContext(), 0.0, image.size.height);
        CGContextScaleCTM(UIGraphicsGetCurrentContext(), 1.0, -1.0);
    }
    
    CGContextDrawImage(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, image.size.width, image.size.height), maskedImageRef);
    UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
    CGImageRelease(maskedImageRef);
    UIGraphicsEndImageContext();
    return result;
}

- (UIImage *)inverseColorToImage:(UIImage *)image
{
    CIImage *coreImage = [CIImage imageWithCGImage:image.CGImage];
    CIFilter *filter = [CIFilter filterWithName:@"CIColorInvert"];
    [filter setValue:coreImage forKey:kCIInputImageKey];
    CIImage *result = [filter valueForKey:kCIOutputImageKey];
    return [UIImage imageWithCIImage:result];
}


@end
