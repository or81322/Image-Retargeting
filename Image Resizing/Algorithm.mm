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

@interface Algorithm ()

@property (nonatomic) CGSize targetImageSize;// size already scaled
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
@property (nonatomic , readonly) int defaultGridSize;

@property (nonatomic , readonly) CGFloat minGridHeight;
@property (nonatomic , readonly) CGFloat minGridWidth;

//
@property (nonatomic , strong) UIImage *image;

@end

@implementation Algorithm

using namespace cv;
using namespace std;

#pragma mark - Constants

#define DEFAULT_PERCENTAGE 0.2

#define SCALE [[UIScreen mainScreen] scale]

#pragma mark - init

-(CGSize)currentScreenSize
{
    return [self sizeInOrientation:[UIApplication sharedApplication].statusBarOrientation];
}

-(CGSize)sizeInOrientation:(UIInterfaceOrientation)orientation
{
    CGSize size = [UIScreen mainScreen].bounds.size;
    if (UIInterfaceOrientationIsLandscape(orientation))
    {
        size = CGSizeMake(size.height, size.width);
    }
    return size;
}

-(id)init {
    // default device size in pixels
    CGSize screenSize = [self currentScreenSize];
    CGSize targetImageSize = CGSizeMake(screenSize.width * SCALE , screenSize.height * SCALE);
    
    //default percentage
    CGFloat percentage = DEFAULT_PERCENTAGE;
    
    //default saliency filter
    GPUImageSobelEdgeDetectionSaliencyFilter *saliencyFilter = [[GPUImageSobelEdgeDetectionSaliencyFilter alloc] init];
    
    return [self initWithTargetImageSize:targetImageSize andPercentage:percentage usingSaliencyFilter:saliencyFilter];
}

-(id)initWithTargetImageSize:(CGSize)targetImageSize andPercentage:(CGFloat)percentage usingSaliencyFilter:(SaliencyFilter *)saliencyFilter{
    if (self = [super init]) {
        _targetImageSize = targetImageSize;
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
    return DEFAULT_NUMBER_OF_GRID_ROWS;
}

-(NSUInteger)numberOfGridCols {
    return DEFAULT_NUMBER_OF_GRID_COLS;
}

-(int)defaultGridSize {
    return (int) (self.numberOfGridRows + self.numberOfGridCols);
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

- (Mat)getSaliencyMap:(UIImage *)saliencyImage {
    return [self cvMatFromUIImage:[saliencyImage scaleToSize:CGSizeMake(self.numberOfGridRows, self.numberOfGridCols)]];
}

-(UIImage *)retargeting:(UIImage *)image withSaliencyImage:(UIImage *)saliencyImage {
    self.image = image;
    //return saliencyImage;
    
    // average saliency
    Mat saliencyMap = [self getSaliencyMap:saliencyImage];
    //return [self UIImageFromCVMat:saliencyMap];
    
    // ASAP Energy
    Mat K = Mat(self.numberOfGridRows * self.numberOfGridCols, self.defaultGridSize, CV_64F);
    
    double rowHeight = (double) self.imageHeight / self.numberOfGridRows;
    double colWidth = (double) self.imageWidth / self.numberOfGridCols;
    
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
                //K.at<double>(k, l) = saliencyValue * self.numberOfGridRows / self.imageHeight;
                K.at<double>(k, l) = saliencyValue / rowHeight;
            } else if (l == (self.numberOfGridRows + c)) {
                //K.at<double>(k, l) = -1 * saliencyValue * self.numberOfGridCols / self.imageWidth;
                K.at<double>(k, l) = -1 * saliencyValue / colWidth;
            } else {
                K.at<double>(k, l) = 0;
            }
        }
    }
    
    Mat Q = K.t() * K;
    Mat b = Mat::zeros(self.defaultGridSize, 1, CV_64F);// needed?
    
    // solve the QP problem
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
    
    NSArray *s = [CVXSolver solveWithCvxParams:cvxParams];
    
    free(cvxParams->Q);
    free(cvxParams->b);
    free(cvxParams);
    
    // Image resizing and deformation
    NSArray *sRows = [s objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, self.numberOfGridRows)]];
    NSArray *sCols = [s objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(self.numberOfGridRows, self.numberOfGridCols)]];
    
    NSMutableArray *sRowsRounded = [[NSMutableArray alloc] initWithCapacity:[sRows count]];
    NSMutableArray *sColsRounded = [[NSMutableArray alloc] initWithCapacity:[sCols count]];
    
    for (int i = 0; i < [sRows count]; ++i)
        sRowsRounded[i] = [NSNumber numberWithDouble:round([(NSNumber *)sRows[i] doubleValue])];
    for (int j = 0; j < [sCols count]; ++j)
        sColsRounded[j] = [NSNumber numberWithDouble:round([(NSNumber *)sCols[j] doubleValue])];
    
    Mat q;
    Mat img = [self cvMatFromUIImage:self.image];
    int startCol, endCol;
    
    for (int j = 0; j < self.numberOfGridCols; ++j) {
        startCol = floor(j * colWidth);
        endCol = ceil((j + 1) * colWidth) - 1;
        if (endCol == (j + 1) * colWidth  - 1) {
            ++endCol;
        }
        
        if (j == 0) {
            resize(img.colRange(startCol, endCol), q, cv::Size([sColsRounded[j] intValue], img.rows));
            continue;
        }
        Mat tmp;
        resize(img.colRange(startCol, endCol), tmp, cv::Size([sColsRounded[j] intValue], img.rows));
        hconcat(q, tmp, q);
    }
    Mat deformatedImage;
    int startRow, endRow;
    
    for (int i = 0; i < self.numberOfGridRows; ++i) {
        startRow = floor(i * rowHeight);
        endRow = ceil((i + 1) * rowHeight) - 1;
        if (endRow == (i + 1) * rowHeight  - 1) {
            ++endRow;
        }
        
        if (i == 0) {
            resize(q.rowRange(startRow, endRow), deformatedImage, cv::Size(q.cols, [sRowsRounded[i] intValue]));
            continue;
        }
        Mat tmp;
        resize(q.rowRange(startRow, endRow), tmp, cv::Size(q.cols, [sRowsRounded[i] intValue]));
        vconcat(deformatedImage, tmp, deformatedImage);
    }
    
    UIImage *output = [self UIImageFromCVMat:deformatedImage];
    return output;
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
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef scale:1.0 orientation:self.image.imageOrientation];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return finalImage;
}

@end