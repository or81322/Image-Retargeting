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
#import "UIImage+Resize.h"
#import "UIImage+Alpha.h"

@interface Algorithm ()

//
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

@end

@implementation Algorithm

@synthesize saliencyImage = _saliencyImage;

using namespace cv;
using namespace std;

#pragma mark - Constants

#define DEFAULT_PERCENTAGE 0.2f

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
    return [self initWithImage:nil];
}

- (id)initWithImage:(UIImage *)image{
    // default device size in pixels
    CGSize screenSize = [self currentScreenSize];
    CGSize targetImageSize = CGSizeMake(screenSize.width * SCALE , screenSize.height * SCALE);
    
    //default percentage
    CGFloat percentage = DEFAULT_PERCENTAGE;
    //default percentage
    
    return [self initWithImage:image andTargetImageSize:targetImageSize andPercentage:percentage];
}

- (id)initWithImage:(UIImage *)image andTargetImageSize:(CGSize)targetImageSize andPercentage:(CGFloat)percentage{
    return [self initWithImage:image andTargetImageSize:targetImageSize andPercentage:percentage andSaliencyImage:nil];
}

-(id)initWithImage:(UIImage *)image andTargetImageSize:(CGSize)targetImageSize andPercentage:(CGFloat)percentage andSaliencyImage:(UIImage *)saliencyImage{
    if (self = [super init]) {
        _targetImageSize = targetImageSize;
        _percentage = percentage;
        _image = image;
        _saliencyImage = saliencyImage;
        
        //default saliency filter
        _saliencyFilter = [[GPUImageSobelEdgeDetectionSaliencyFilter alloc] init];
    }
    return self;
}

/*
-(id)initWithImage:(UIImage *)image andTargetImageSize:(CGSize)targetImageSize andPercentage:(CGFloat)percentage andSaliencyImage:(UIImage *)saliencyImage usingSaliencyFilter:(SaliencyFilter *)saliencyFilter{
    if (self = [super init]) {
        _targetImageSize = targetImageSize;
        _percentage = percentage;
        _saliencyFilter = saliencyFilter;
        _image = image;
        _saliencyImage = saliencyImage;
    }
    return self;
}
 */

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


-(CGFloat)minGridHeight {
    return self.percentage * self.imageHeight / self.numberOfGridRows ;
}

-(CGFloat)minGridWidth {
    return self.percentage * self.imageWidth / self.numberOfGridCols ;
}

-(UIImage *)saliencyImage {
    if (_saliencyImage == nil) {
        if (self.image) {
            _saliencyImage = [self.saliencyFilter getSaliencyImageFromImage:self.image];
        }
    }
    return _saliencyImage;
}

-(void)setSaliencyImage:(UIImage *)saliencyImage{
    if (CGSizeEqualToSize(self.image.size, saliencyImage.size)) {
        _saliencyImage = saliencyImage;
    }
    // need to make sure that the image and its saliency image are with the same size
}

#pragma mark - assertions

-(BOOL)isCroppingNeeded {
    return !((self.targetImageHeight / self.numberOfGridRows >= self.minGridHeight) && (self.targetImageWidth / self.numberOfGridCols >= self.minGridWidth));
}

#pragma mark - algorithm

-(UIImage *)autoRetargeting{
    return [self retargeting:self.image withSaliencyImage:self.saliencyImage];
}

- (UIImage *)retargeting:(UIImage *)image withSaliencyImage:(UIImage *)saliencyImage {
    if (self.image == nil) {
        self.image = image;
    }
    
    // average saliency
    Mat saliencyMap = [self getSaliencyMapFromSaliencyImage:saliencyImage];
    
    // ASAP Energy
    Mat K = Mat(self.numberOfGridRows * self.numberOfGridCols, self.numberOfGridRows + self.numberOfGridCols, CV_64F);
    
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
    Mat b = Mat::zeros(self.numberOfGridRows + self.numberOfGridCols, 1, CV_64F);// needed?
    
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
    
    saliencyMap.release();
    K.release();
    Q.release();
    b.release();
    
    // Image resizing and deformation
    NSArray *sRows = [s objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, self.numberOfGridRows)]];
    NSArray *sCols = [s objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(self.numberOfGridRows, self.numberOfGridCols)]];
    
    NSMutableArray *sRowsRounded = [[NSMutableArray alloc] initWithCapacity:[sRows count]];
    NSMutableArray *sColsRounded = [[NSMutableArray alloc] initWithCapacity:[sCols count]];
    for (int i = 0; i < [sRows count]; ++i)
        sRowsRounded[i] = [NSNumber numberWithDouble:round([(NSNumber *)sRows[i] doubleValue])];
    for (int j = 0; j < [sCols count]; ++j)
        sColsRounded[j] = [NSNumber numberWithDouble:round([(NSNumber *)sCols[j] doubleValue])];
    
    Mat img = [self cvMatFromUIImage:self.image];
    //return [self UIImageFromCVMat:img];
    
    Mat q;
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
    
    img.release();
    
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
    
    q.release();
    
    UIImage *output = [self UIImageFromCVMat:deformatedImage];

    deformatedImage.release();
    
    return output;
}

#pragma mark - private methods

- (Mat)getSaliencyMapFromSaliencyImage:(UIImage *)saliencyImage {
    return [self cvMatFromUIImage:[saliencyImage scaleToSize:CGSizeMake(self.numberOfGridRows, self.numberOfGridCols)]];
    
    //return [self cvMatFromUIImage:[saliencyImage resizedImage:CGSizeMake(self.numberOfGridRows, self.numberOfGridCols) interpolationQuality:kCGInterpolationNone]];
    
    /*
     cv::Size size(self.numberOfGridRows, self.numberOfGridCols);
     Mat saliencyMap;
     resize([self cvMatFromUIImage:saliencyImage], saliencyMap, size);
     return saliencyMap;
     */
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
