//
//  ImageFilter.m
//  Image Resizing
//
//  Created by Or Maayan on 8/11/14.
//  Copyright (c) 2014 Or Maayan & Micheal Leybovich. All rights reserved.
//

#import "SaliencyFilter.h"

@implementation SaliencyFilter

-(UIImage *)getSaliencyImage:(UIImage *)image{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

@end
