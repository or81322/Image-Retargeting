//
//  UIImage+FixOrientation.h
//  Image Resizing
//
//  Created by or maayan on 8/27/14.
//  Copyright (c) 2014 Or Maayan & Micheal Leybovich. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (FixOrientation)

- (UIImage *)fixOrientation;
- (UIImage *)fixOrientationForScaledImage;// taking scale into account, so will work for 2x images.

@end
