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
@property (strong, nonatomic) UIImage *maskedSaliencyImage;
@property (strong, nonatomic) UIImage *originalSaliency;


@property (nonatomic , strong) Algorithm *algorithm;

@property (nonatomic) BOOL isShowingSaliency;

@property (strong, nonatomic) UIImage *saliencyDrawImage;
@property (strong, nonatomic) UIImage *drawImage;
@property (nonatomic) BOOL didDraw;

@property (weak, nonatomic) IBOutlet UIImageView *drawImageView;
@property (weak, nonatomic) IBOutlet UIImageView *tempDrawImageView;

@property (nonatomic) CGPoint lastPoint;
@property (nonatomic) CGFloat red;
@property (nonatomic) CGFloat green;
@property (nonatomic) CGFloat blue;
@property (nonatomic) CGFloat brush;
@property (nonatomic) CGFloat opacity;
@property (nonatomic) BOOL mouseSwiped;

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
    self.red = 255.0/255.0;
    self.green = 255.0/255.0;
    self.blue = 255.0/255.0;
    self.brush = 35.0;
    self.opacity = 0.8;
    
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    // TODO - remove later
    self.image = self.imageView.image;
    
    //self.algorithm = [[Algorithm alloc] initWithImage:self.image];
    self.originalSaliency = self.algorithm.saliencyImage;
    
    [self.imageView.layer setBorderColor: [[UIColor whiteColor] CGColor]];
    [self.imageView.layer setBorderWidth: 6.0];
    [self.imageView setFrame:AVMakeRectWithAspectRatioInsideRect(self.imageView.image.size, self.saliencyImageView.frame)];
    [self.drawImageView setFrame:AVMakeRectWithAspectRatioInsideRect(self.imageView.image.size, self.saliencyImageView.frame)];
    [self.tempDrawImageView setFrame:AVMakeRectWithAspectRatioInsideRect(self.imageView.image.size, self.saliencyImageView.frame)];


    //[self.saliencyImageView.layer setBorderColor: [[UIColor whiteColor] CGColor]];
    //[self.saliencyImageView.layer setBorderWidth: 6.0];
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
            [self.drawImageView setFrame:AVMakeRectWithAspectRatioInsideRect(self.imageView.image.size, self.saliencyImageView.frame)];
            [self.tempDrawImageView setFrame:AVMakeRectWithAspectRatioInsideRect(self.imageView.image.size, self.saliencyImageView.frame)];
        }
    }
}

#pragma mark - Properties

@synthesize image = _image;
//@synthesize saliencyImage = _saliencyImage;

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

-(Algorithm *)algorithm {
    if (_algorithm == nil) {
        _algorithm = [[Algorithm alloc] init];
        _algorithm.image = self.image;
        //_algorithm.saliencyImage = self.saliencyImage;
    }
    return _algorithm;
}

- (UIImage *)originalSaliency {
    if (_originalSaliency == nil) {
        _originalSaliency = self.algorithm.saliencyImage;
    }
    return _originalSaliency;
}

-(void)setImage:(UIImage *)image {
    self.algorithm.saliencyImage = nil;
    self.algorithm.image = image;
    _image = image;
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
        self.maskedSaliencyImage = nil;
        //self.saliencyImageView.image = nil;
        self.saliencyDrawImage = nil;
        //self.drawImageView.image = nil;
        self.drawImage = nil;
        self.didDraw = false;
        self.originalSaliency = nil;
        [self.algorithm recalculateSaliency];
 
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
        
        if (self.isShowingSaliency)
            [self toggleSaliency];
        
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
        
        self.algorithm.targetImageSize = CGSizeMake(targetimageWidth, targetImageHeight);
        
        UIImage *modifiedImage = [self.algorithm autoRetargeting];
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

#pragma mark - saliency related

- (void)toggleSaliency {
    if (self.isShowingSaliency) {
        self.saliencyImageView.image = nil;
        self.drawImageView.image = nil;
        
        if (self.didDraw) {
            //UIGraphicsBeginImageContextWithOptions(self.saliencyImageView.frame.size, NO, 0.0);
            UIGraphicsBeginImageContext(self.saliencyImageView.frame.size);
            [self.algorithm.saliencyImage drawInRect:CGRectMake(0, 0, self.saliencyImageView.frame.size.width, self.drawImageView.frame.size.height) blendMode:kCGBlendModeNormal alpha:1.0];
            [self.saliencyDrawImage drawInRect:CGRectMake(0, 0, self.saliencyImageView.frame.size.width, self.saliencyImageView.frame.size.height) blendMode:kCGBlendModeNormal alpha:1.0];
            
            UIImage *temp = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            self.algorithm.saliencyImage = temp;
            self.didDraw = NO;
            //self.maskedSaliencyImage = self.algorithm.saliencyImage;
            self.maskedSaliencyImage = nil;
            
            self.drawImage = nil;
        }
    }
    else {
        if (self.maskedSaliencyImage)
            self.saliencyImageView.image = self.maskedSaliencyImage;
        else {
            UIImage *maskedImage = [self maskImage2:self.algorithm.saliencyImage withMask:self.image];
            //[self updateImageViewWithImage:maskedImage];
        
            //saliencyImage = [self changeColorToTransparent:saliencyImage];
            //maskedImage = [self maskImage2:self.algorithm.saliencyImage withMask:self.image];
        
            self.saliencyImageView.image = maskedImage;
            self.maskedSaliencyImage = maskedImage;// saliency image is not saliency as in the algorithm. it's the masked saliency.
        }
        [self updateImageViewWithImage:self.image];
        //self.imageView.image = nil;
        self.drawImageView.image = self.drawImage;
    }
    self.isShowingSaliency = !self.isShowingSaliency;
}

- (IBAction)toggleSaliency:(id)sender {
    [self toggleSaliency];
}

- (UIImage *)maskImage2:(UIImage *)image withMask:(UIImage *)mask
{
    CGImageRef imageReference = image.CGImage;
    UIImage *maskWithAlpha = [mask imageByApplyingAlpha:1];
    
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
    if (mask == nil) return image;
    CGImageRef imageReference = image.CGImage;
    UIImage *maskWithAlpha = [mask imageByApplyingAlpha:1];
    
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

#pragma mark - Drawer
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    if (!self.isShowingSaliency)
        return;
    
    self.mouseSwiped = NO;
    UITouch *touch = [touches anyObject];
    self.lastPoint = [touch locationInView:self.drawImageView];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    
    if (!self.isShowingSaliency)
        return;
    
    self.mouseSwiped = YES;
    UITouch *touch = [touches anyObject];
    CGPoint currentPoint = [touch locationInView:self.drawImageView];
    
    UIGraphicsBeginImageContext(self.drawImageView.frame.size);
    [self.tempDrawImageView.image drawInRect:CGRectMake(0, 0, self.drawImageView.frame.size.width, self.drawImageView.frame.size.height)];
    CGContextMoveToPoint(UIGraphicsGetCurrentContext(), self.lastPoint.x, self.lastPoint.y);
    CGContextAddLineToPoint(UIGraphicsGetCurrentContext(), currentPoint.x, currentPoint.y);
    CGContextSetLineCap(UIGraphicsGetCurrentContext(), kCGLineCapRound);
    CGContextSetLineWidth(UIGraphicsGetCurrentContext(), self.brush );
    CGContextSetRGBStrokeColor(UIGraphicsGetCurrentContext(), self.red, self.green, self.blue, 1.0);
    CGContextSetBlendMode(UIGraphicsGetCurrentContext(),kCGBlendModeNormal);
    
    CGContextStrokePath(UIGraphicsGetCurrentContext());
    self.tempDrawImageView.image = UIGraphicsGetImageFromCurrentImageContext();
    [self.tempDrawImageView setAlpha:self.opacity];
    UIGraphicsEndImageContext();
    
    self.lastPoint = currentPoint;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    
    if (!self.isShowingSaliency)
        return;
    
    if(!self.mouseSwiped) {
        UIGraphicsBeginImageContext(self.drawImageView.frame.size);
        [self.tempDrawImageView.image drawInRect:CGRectMake(0, 0, self.drawImageView.frame.size.width, self.drawImageView.frame.size.height)];
        CGContextSetLineCap(UIGraphicsGetCurrentContext(), kCGLineCapRound);
        CGContextSetLineWidth(UIGraphicsGetCurrentContext(), self.brush);
        CGContextSetRGBStrokeColor(UIGraphicsGetCurrentContext(), self.red, self.green, self.blue, self.opacity);
        CGContextMoveToPoint(UIGraphicsGetCurrentContext(), self.lastPoint.x, self.lastPoint.y);
        CGContextAddLineToPoint(UIGraphicsGetCurrentContext(), self.lastPoint.x, self.lastPoint.y);
        CGContextStrokePath(UIGraphicsGetCurrentContext());
        CGContextFlush(UIGraphicsGetCurrentContext());
        self.tempDrawImageView.image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    self.drawImageView.image = self.drawImage;
    
    UIGraphicsBeginImageContext(self.drawImageView.frame.size);
    [self.saliencyDrawImage drawInRect:CGRectMake(0, 0, self.drawImageView.frame.size.width, self.drawImageView.frame.size.height) blendMode:kCGBlendModeNormal alpha:1.0];
    [self.tempDrawImageView.image drawInRect:CGRectMake(0, 0, self.drawImageView.frame.size.width, self.drawImageView.frame.size.height) blendMode:kCGBlendModeNormal alpha:self.opacity];
    self.saliencyDrawImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    UIGraphicsBeginImageContext(self.drawImageView.frame.size);
    [self.drawImageView.image drawInRect:CGRectMake(0, 0, self.drawImageView.frame.size.width, self.drawImageView.frame.size.height) blendMode:kCGBlendModeNormal alpha:1.0];
    [self.tempDrawImageView.image drawInRect:CGRectMake(0, 0, self.drawImageView.frame.size.width, self.drawImageView.frame.size.height) blendMode:kCGBlendModeNormal alpha:self.opacity];
    self.drawImageView.image = UIGraphicsGetImageFromCurrentImageContext();
    self.tempDrawImageView.image = nil;
    UIGraphicsEndImageContext();
    
    self.didDraw = YES;
    self.drawImage = self.drawImageView.image;
}

- (void)resetDrawing {
    self.drawImageView.image = nil;
    self.drawImage = nil;
    self.didDraw = false;
    
    self.saliencyDrawImage = nil;
    
    self.algorithm.saliencyImage = self.originalSaliency;
    self.maskedSaliencyImage = [self maskImage2:self.algorithm.saliencyImage withMask:self.image];
    
    if (!self.isShowingSaliency)
        [self toggleSaliency];
    else
        self.saliencyImageView.image = self.maskedSaliencyImage;
}

- (IBAction)resetDrawing:(id)sender {
    [self resetDrawing];
}


@end
