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
    //GPUImageOpeningFilter *dilationFilter                     = [[GPUImageOpeningFilter alloc] initWithRadius:4];
    //GPUImageClosingFilter *dilationFilter                     = [[GPUImageClosingFilter alloc] initWithRadius:4];
    //GPUImageErosionFilter *dilationFilter                     = [[GPUImageErosionFilter alloc] initWithRadius:4];
    GPUImageDilationFilter *dilationFilter                     = [[GPUImageDilationFilter alloc] initWithRadius:4];
    
    GPUImageSobelEdgeDetectionFilter *sobelEdgeDetectionFilter = [[GPUImageSobelEdgeDetectionFilter alloc] init];
    
    GPUImagePicture *stillImageSource                          = [[GPUImagePicture alloc] initWithImage:image];
    
    [stillImageSource addTarget:sobelEdgeDetectionFilter];
    [sobelEdgeDetectionFilter addTarget:dilationFilter];
    
    [dilationFilter useNextFrameForImageCapture];
    
    [stillImageSource processImage];
    
    return [dilationFilter imageFromCurrentFramebufferWithOrientation:image.imageOrientation];
}


@end
