//
//  CVXSolver.m
//  Image Resizing
//
//  Created by michael leybovich on 8/16/14.
//  Copyright (c) 2014 Or Maayan & Micheal Leybovich. All rights reserved.
//

#import "CVXSolver.h"
#import "solver.h"

typedef struct {
    double *Q;
    double *b;
    double imageHeight;
    double imageWidth;
    double targetHeight;
    double targetWidth;
} CvxParams;

@interface CVXSolver ()
//
@property (nonatomic) Vars vars;
@property (nonatomic) Params params;
@property (nonatomic) Workspace work;
@property (nonatomic) Settings settings;

@end

@implementation CVXSolver

#define DEFAULT_NUMBER_OF_GRID_ROWS 25
#define DEFAULT_NUMBER_OF_GRID_COLS 25
#define DEFAULT_GRID_SIZE (DEFAULT_NUMBER_OF_GRID_ROWS + DEFAULT_NUMBER_OF_GRID_COLS)

- (void)loadDataWithParams:(CvxParams)cvxParams {
    params.imageHeight[0] = cvxParams.imageHeight;
    params.imageWidth[0] = cvxParams.imageWidth;
    params.targetHeight[0] = cvxParams.targetHeight;
    params.targetWidth[0] = cvxParams.targetWidth;
    
    for (int i = 0; i < DEFAULT_GRID_SIZE; ++i)
        params.b[i] = cvxParams.b[i];
    
    for (int i = 0; i < DEFAULT_GRID_SIZE; ++i)
        for (int j = 0; j < DEFAULT_GRID_SIZE; ++j)
            params.Q[i*DEFAULT_GRID_SIZE + j] = cvxParams.Q[i*DEFAULT_GRID_SIZE + j];
}

- (NSArray *)solveWithCvxParams:(CvxParams)cvxParams {
    set_defaults();
    setup_indexing();
    [self loadDataWithParams:cvxParams];
    
    /* Solve problem instance for the record. */
    settings.verbose = 1;
    solve();
    
    NSMutableArray *s = [[NSMutableArray alloc] initWithCapacity:DEFAULT_GRID_SIZE];
    
    for (int i = 0; i < DEFAULT_GRID_SIZE; ++i)
        [s insertObject:[NSNumber numberWithDouble:vars.s[i]] atIndex:i];
    
    return s;
}

@end
