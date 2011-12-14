//
//  ShiftIt_Tests.m
//  ShiftIt Tests
//
//  Created by Filip Krikava on 01/12/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "SIAdjacentRectTest.h"
#import "SIAdjacentRect.h"

#define MR(x,y,w,h) [NSValue valueWithRect:NSMakeRect((x),(y),(w),(h))]

@implementation SIAdjacentRectTest

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testTwoRectangles {
    NSArray *rectangles = [NSArray arrayWithObjects:MR(5,5,5,5), MR(11,6,3,3), nil];
    NSArray *values = [NSArray arrayWithObjects:@"A", @"B", nil];

    SIAdjacentRect *rects = [SIAdjacentRect adjacentRect:rectangles forValues:values];

    STAssertEquals(1, [[rects rectsInDirection:kRightDirection] count], @"There is only one rectangle in right direction");
    STAssertEqualObjects(@"B", [[rects rectsInDirection:kRightDirection] objectAtIndex:0], @"Rectangle B is right of A");
}

@end
