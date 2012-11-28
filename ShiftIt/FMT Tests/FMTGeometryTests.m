/*
 Copyright (c) 2010-2011 Filip Krikava

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 */

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
