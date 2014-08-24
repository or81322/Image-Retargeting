//
//  ViewController.m
//  Image Resizing
//
//  Created by Or Maayan on 8/2/14.
//  Copyright (c) 2014 Or Maayan & Michael Leybovich. All rights reserved.
//

#import "ViewController.h"
#import "Algorithm.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@end

@implementation ViewController

- (void)setImage:(UIImage *)image
{
    _image = image;
    [self updateImageView];
}

- (void)updateImageView {
    if (self.imageView) {
        if (self.image) {
            self.imageView.image = self.image;
        }
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    [self updateImageView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)startAutomaticRetargeting:(id)sender {
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
    [[self navigationController] setNavigationBarHidden:YES animated:YES];
    
    self.imageView.image = [([[Algorithm alloc] init]) autoRetargeting:self.imageView.image];
}

- (IBAction)userTouchedTheScreen:(id)sender {
    [[UIApplication sharedApplication] setStatusBarHidden:![[UIApplication sharedApplication] isStatusBarHidden] withAnimation:UIStatusBarAnimationSlide];
    [self.navigationController setNavigationBarHidden:!self.navigationController.navigationBar.isHidden animated:YES];
}

/*
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    // TODO
}
 */

@end
