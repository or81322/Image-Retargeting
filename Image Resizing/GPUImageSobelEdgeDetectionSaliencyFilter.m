//
//  GPUImageSobelEdgeDetectionSaliencyFilter.m
//  Image Resizing
//
//  Created by Or Maayan on 8/11/14.
//  Copyright (c) 2014 Or Maayan & Micheal Leybovich. All rights reserved.
//

#import "GPUImageSobelEdgeDetectionSaliencyFilter.h"
#import "GPUImage.h"

@implementation GPUImageSobelEdgeDetectionSaliencyFilter

-(UIImage *)getSaliencyImage:(UIImage *)image {
    GPUImagePicture *stillImageSource = [[GPUImagePicture alloc] initWithImage:image];
    GPUImageGrayscaleFilter *grayscaleFilter = [[GPUImageGrayscaleFilter alloc] init];
    GPUImageSobelEdgeDetectionFilter *sobelEdgeDetectionFilter = [[GPUImageSobelEdgeDetectionFilter alloc] init];
    
    [stillImageSource addTarget:grayscaleFilter];
    [stillImageSource addTarget:sobelEdgeDetectionFilter];
    
    [sobelEdgeDetectionFilter useNextFrameForImageCapture];
    [stillImageSource processImage];
    
    return [sobelEdgeDetectionFilter imageFromCurrentFramebuffer];
}


@end
