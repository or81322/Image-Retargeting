//
//  Algorithm.m
//  Image Resizing
//
//  Created by Or Maayan on 8/2/14.
//  Copyright (c) 2014 Or Maayan & Micheal Leybovich. All rights reserved.
//

#import "Algorithm.h"
#import "UIImage+Grayscale.h"

@interface Algorithm()

@property (nonatomic, strong) UIImage *image;
@property (nonatomic) NSInteger targetHeight;
@property (nonatomic) NSInteger targetWidth;
@property (nonatomic) NSInteger gridNumOfRows;
@property (nonatomic) NSInteger gridNumOfCols;
@property (nonatomic) NSInteger imageHeight;
@property (nonatomic) NSInteger imageWidth;

@end

@implementation Algorithm

- (id)init
{
    self = [super init];
    
    if (self) {
        _image = [UIImage imageNamed:@"Desert.jpg"];
    }
    
    return self;
}

- (void)calculateThings
{
    UIImage *grayImage = [self.image convertToGrayscale];
    
}

@end
