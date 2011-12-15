//
//  FMT_Tests.m
//  FMT Tests
//
//  Created by Filip Krikava on 14/12/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import "FMTGeometry.h"

@interface FMTGeometryTests : SenTestCase

@end

@implementation FMTGeometryTests

- (void)testMakeVector {
    FMTVect v = FMTMakeVect(1, 1, 3, 4);
    
    STAssertEquals(2.0, v.x, @"Invalid x coordinate of the vector");
    STAssertEquals(3.0, v.y, @"Invalid y coordinate of the vector");
}

- (void)testMakePerpendicularVector {
    FMTVect v = FMTMakeVect(1, 1, 3, 4);
    FMTVect n = FMTMakePerpendicularVect(v);

    STAssertEquals(3.0, n.x, @"Invalid x coordinate of the vector");
    STAssertEquals(-2.0, n.y, @"Invalid y coordinate of the vector");
}

- (void)testAbs {
    FMTVect v = FMTMakeVect(1, 1, 3, 3);
    STAssertEqualsWithAccuracy(2.82842712475, FMTAbsVect(v), 0.01, @"Invalid length of a vecotr");
}

- (void)testPointDistance {
    NSPoint a = NSMakePoint(0, 0);
    NSPoint b = NSMakePoint(0, 4);
    NSPoint p = NSMakePoint(5, 3);

    STAssertEqualsWithAccuracy(5.0, FMTPointDistanceToLine(a, b, p), 0.01, @"Invalid point distance to vector");
}

- (void)testAngleBetweenVects {
    FMTVect u = FMTMakeVect(0, 0, 0, 10);
    FMTVect v = FMTMakePerpendicularVect(u);

    STAssertEquals(90.0, FMTAngleBetweenVects(u, v), @"Invalid angle between vectors");
}

- (void)testDirectionBetweenVects {
    FMTVect u = {0, 1};
    FMTVect v = {1, 0};
    
    STAssertEquals(kRightDirection, FMTDirectionBetweenVects(u, v), @"Invalid direction");
}

@end
