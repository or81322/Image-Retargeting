//
//  Algorithm.m
//  Image Resizing
//
//  Created by Or Maayan on 8/2/14.
//  Copyright (c) 2014 Or Maayan & Micheal Leybovich. All rights reserved.
//

#import "Algorithm.h"

@interface Algorithm ()

@property (nonatomic) CGSize targetImageSize;// size already scaled
@property (nonatomic) CGSize gridSize;// size in positive integers
@property (nonatomic) CGFloat percentage;// ?
@property (nonatomic , strong) SaliencyFilter *saliencyFilter;

//
@property (nonatomic , readonly) NSUInteger targetImageHeight;// in pixels
@property (nonatomic , readonly) NSUInteger targetImageWidth;// in pixels

@property (nonatomic , readonly) NSUInteger imageHeight;// in pixels
@property (nonatomic , readonly) NSUInteger imageWidth;// in pixels

//
@property (nonatomic , readonly) NSUInteger numberOfGridRows;
@property (nonatomic , readonly) NSUInteger numberOfGridCols;

@property (nonatomic , readonly) CGFloat minGridHeight;
@property (nonatomic , readonly) CGFloat minGridWidth;

//
@property (nonatomic , weak) UIImage *image;

@end

@implementation Algorithm

#pragma mark - Constants

#define DEFAULT_NUMBER_OF_GRID_ROWS 25
#define DEFAULT_NUMBER_OF_GRID_COLS 25

#define DEFAULT_PERCENTAGE 0.2

#define SCALE [[UIScreen mainScreen] scale]

#pragma mark - init

-(id)init {
    // default device size in pixels
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    CGSize targetImageSize = CGSizeMake(screenBounds.size.width * SCALE , screenBounds.size.height * SCALE);
    
    // default grid size
    CGSize gridSize = CGSizeMake(DEFAULT_NUMBER_OF_GRID_ROWS , DEFAULT_NUMBER_OF_GRID_COLS);
    
    //default percentage
    CGFloat percentage = DEFAULT_PERCENTAGE;
    
    //default saliency filter
    SaliencyFilter *saliencyFilter = [[SaliencyFilter alloc] init];
    
    return [self initWithTargetImageSize:targetImageSize andGridSize:gridSize andPercentage:percentage usingSaliencyFilter:saliencyFilter];
}

-(id)initWithTargetImageSize:(CGSize)targetImageSize andGridSize:(CGSize)gridSize andPercentage:(CGFloat)percentage usingSaliencyFilter:(SaliencyFilter *)saliencyFilter{
    if (self = [super init]) {
        _targetImageSize = targetImageSize;
        _gridSize = gridSize;
        _percentage = percentage;
        _saliencyFilter = saliencyFilter;
    }
    return self;
}

# pragma mark - Properties

-(NSUInteger)targetImageHeight {
    return self.targetImageSize.height;
}

-(NSUInteger)targetImageWidth {
    return self.targetImageSize.width;
}


-(NSUInteger)imageHeight {
    return self.image.size.height * SCALE ;
}

-(NSUInteger)imageWidth {
    return self.image.size.width * SCALE ;
}

//
-(NSUInteger)numberOfGridRows {
    return self.gridSize.height;
}

-(NSUInteger)numberOfGridCols {
    return self.gridSize.width;
}


-(CGFloat)minGridHeight {
    return self.percentage * self.imageHeight / self.numberOfGridRows ;
}

-(CGFloat)minGridWidth {
    return self.percentage * self.imageWidth / self.numberOfGridCols ;
}

#pragma mark - algorithm

-(UIImage *)autoRetargeting:(UIImage *)image {
    return [self retargeting:image withSaliencyImage:[self.saliencyFilter getSaliencyImage:image]];
}

-(UIImage *)retargeting:(UIImage *)image withSaliencyImage:(UIImage *)saliencyImage {
    self.image = image;
    
    // TODO
    
    return nil;
}

@end
