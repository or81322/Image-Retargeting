//
//  CVXSolver.h
//  Image Resizing
//
//  Created by michael leybovich on 8/16/14.
//  Copyright (c) 2014 Or Maayan & Micheal Leybovich. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CVXSolver : NSObject

typedef struct {
    double *Q;
    double *b;
    double imageHeight;
    double imageWidth;
    double targetHeight;
    double targetWidth;
} CvxParams;

+ (NSArray *)solveWithCvxParams:(CvxParams *)cvxParams;

extern const int DEFAULT_NUMBER_OF_GRID_ROWS;
extern const int DEFAULT_NUMBER_OF_GRID_COLS;

@end
