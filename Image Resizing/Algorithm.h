//
//  Algorithm.h
//  Image Resizing
//
//  Created by Or Maayan on 8/2/14.
//  Copyright (c) 2014 Or Maayan & Micheal Leybovich. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SaliencyFilter.h"

@interface Algorithm : NSObject

- (id)initWithTargetImageSize:(CGSize)targetImageSize andPercentage:(CGFloat)percentage usingSaliencyFilter:(SaliencyFilter *)saliencyFilter;
- (id)initWithTargetImageSize:(CGSize)targetImageSize;

//

- (BOOL)isCroppingNeeded;

//

- (UIImage *)autoRetargeting:(UIImage *)image;

- (UIImage *)retargeting:(UIImage *)image withSaliencyImage:(UIImage *)saliencyImage;

@end
