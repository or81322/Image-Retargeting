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

@property (nonatomic) CGSize targetImageSize;
@property (nonatomic) CGFloat percentage;

@property (nonatomic , weak) UIImage *image;
@property (nonatomic , weak) UIImage *saliencyImage;

//

- (id)initWithImage:(UIImage *)image;
- (id)initWithImage:(UIImage *)image andTargetImageSize:(CGSize)targetImageSize andPercentage:(CGFloat)percentage;
- (id)initWithImage:(UIImage *)image andTargetImageSize:(CGSize)targetImageSize andPercentage:(CGFloat)percentage andSaliencyImage:(UIImage *)saliencyImage;// needed?

//

@property (readonly , getter=isCroppingNeeded) BOOL CroppingNeeded;

//

// TODO update saliencyImage method

//

- (UIImage *)autoRetargeting;

- (UIImage *)retargeting:(UIImage *)image withSaliencyImage:(UIImage *)saliencyImage;

@end
