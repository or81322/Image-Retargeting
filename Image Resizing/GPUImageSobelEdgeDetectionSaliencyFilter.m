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
    GPUImageSobelEdgeDetectionFilter *sobelEdgeDetectionFilter = [[GPUImageSobelEdgeDetectionFilter alloc] init];
    
    return [sobelEdgeDetectionFilter imageByFilteringImage:image];
    
    /*
     GPUImageGrayscaleFilter *grayscaleFilter = [[GPUImageGrayscaleFilter alloc] init];
     
     GPUImagePicture *stillImageSource = [[GPUImagePicture alloc] initWithImage:image];
     
     //[stillImageSource addTarget:grayscaleFilter];
     [stillImageSource addTarget:sobelEdgeDetectionFilter];
     
     [sobelEdgeDetectionFilter useNextFrameForImageCapture];
     [stillImageSource processImage];
     
     return [sobelEdgeDetectionFilter imageFromCurrentFramebuffer];
     */
}


@end
