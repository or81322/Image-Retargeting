//
//  Algorithm.m
//  Image Resizing
//
//  Created by Or Maayan on 8/2/14.
//  Copyright (c) 2014 Or Maayan & Micheal Leybovich. All rights reserved.
//

#import "Algorithm.h"
#import "GPUImageSobelEdgeDetectionSaliencyFilter.h"
#import "UIImage+Scale.h"
#import "CVXSolver.h"

//
// Prefix header for all source files using opencv
//
#ifdef __cplusplus
#import <opencv2/opencv.hpp>
#endif

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

using namespace cv;
using namespace std;

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
    GPUImageSobelEdgeDetectionSaliencyFilter *saliencyFilter = [[GPUImageSobelEdgeDetectionSaliencyFilter alloc] init];
    
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
    return self.image.size.height;
}

-(NSUInteger)imageWidth {
    return self.image.size.width;
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

#pragma mark - assertions

-(BOOL)isCroppingNeeded {
    return !((self.targetImageHeight / self.numberOfGridRows >= self.minGridHeight) && (self.targetImageWidth / self.numberOfGridCols >= self.minGridWidth));
}

#pragma mark - algorithm

-(UIImage *)autoRetargeting:(UIImage *)image {
    return [self retargeting:image withSaliencyImage:[self.saliencyFilter getSaliencyImage:image]];
}

-(UIImage *)retargeting:(UIImage *)image withSaliencyImage:(UIImage *)saliencyImage {
    self.image = image;
    
    // average saliency
    Mat saliencyMap = [self cvMatFromUIImage:[saliencyImage scaleToSize:CGSizeMake(self.numberOfGridRows, self.numberOfGridCols)]];
    
    // ASAP Energy
    Mat K = Mat(self.numberOfGridRows * self.numberOfGridCols, self.numberOfGridRows + self.numberOfGridCols, CV_64F);
    
    for (int k = 0 ; k < K.size.p[0] ; k++) {
        int r = k / self.numberOfGridCols ;// floor
        int c = k % self.numberOfGridCols ;
        
        Vec4b intensity = saliencyMap.at<Vec4b>(r, c);
        //uchar blue = intensity.val[0];
        //uchar green = intensity.val[1];
        uchar red = intensity.val[2];
        //uchar alpha = intensity.val[3];
        
        // all the color values are the same if we get gray image
        // so we will use red (randomly chosen)
        double saliencyValue = (double) red / 255;
        
        for (int l = 0 ; l < K.size.p[1] ; l++) {
            if (l == r) {
                K.at<double>(k, l) = saliencyValue * self.numberOfGridRows / self.imageHeight;
            } else if (l == (self.numberOfGridRows + c)) {
                K.at<double>(k, l) = -1 * saliencyValue * self.numberOfGridCols / self.imageWidth;
            } else {
                K.at<double>(k, l) = 0;
            }
        }
    }
    
    Mat Q = K.t() * K;
    Mat b = Mat::zeros(self.numberOfGridRows + self.numberOfGridCols, 1, CV_64F);// needed?
    
    CvxParams *cvxParams = (CvxParams *)malloc(sizeof(CvxParams));
    if (cvxParams == NULL) {
        printf("Cannot malloc memory for struct\n");
		exit(1);  // End program, returning error status.
    }
    cvxParams->Q = [self flatArrayFromMat:Q];
    cvxParams->b = [self flatArrayFromMat:b];
    cvxParams->imageHeight = self.imageHeight;
    cvxParams->imageWidth = self.imageWidth;
    cvxParams->targetHeight = self.targetImageHeight;
    cvxParams->targetWidth = self.targetImageWidth;
    
    NSArray *sol = [CVXSolver solveWithCvxParams:cvxParams];
    
    free(cvxParams->Q);
    free(cvxParams->b);
    free(cvxParams);
    
    return [self UIImageFromCVMat:saliencyMap];

}

- (double *)flatArrayFromMat:(Mat)mat
{
    int cols = mat.cols;
    int rows = mat.rows;
    
    double *flat_mat = (double *)malloc(sizeof(double) * rows * cols);
    if (flat_mat == NULL) {
        printf("Cannot malloc memory for array\n");
		exit(1);  // End program, returning error status.
    }
    
    for (int j = 0; j < cols; ++j)
        for (int i = 0; i < rows; ++i)
            flat_mat[i + j * cols] = mat.at<double>(i, j);
    
    return flat_mat;
}

-(Mat)cvMatFromUIImage:(UIImage *)image
{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels (color channels + alpha)
    
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to  data
                                                    cols,                       // Width of bitmap
                                                    rows,                       // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    
    return cvMat;
}

-(Mat)cvMatGrayFromUIImage:(UIImage *)image
{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    Mat cvMat(rows, cols, CV_8UC1); // 8 bits per component, 1 channels
    
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to data
                                                    cols,                       // Width of bitmap
                                                    rows,                       // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    
    return cvMat;
}

-(UIImage *)UIImageFromCVMat:(Mat)cvMat
{
    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];
    CGColorSpaceRef colorSpace;
    
    if (cvMat.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    // Creating CGImage from Mat
    CGImageRef imageRef = CGImageCreate(cvMat.cols,                                 //width
                                        cvMat.rows,                                 //height
                                        8,                                          //bits per component
                                        8 * cvMat.elemSize(),                       //bits per pixel
                                        cvMat.step[0],                            //bytesPerRow
                                        colorSpace,                                 //colorspace
                                        kCGImageAlphaNone|kCGBitmapByteOrderDefault,// bitmap info
                                        provider,                                   //CGDataProviderRef
                                        NULL,                                       //decode
                                        false,                                      //should interpolate
                                        kCGRenderingIntentDefault                   //intent
                                        );
    
    
    // Getting UIImage from CGImage
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return finalImage;
}

@end
