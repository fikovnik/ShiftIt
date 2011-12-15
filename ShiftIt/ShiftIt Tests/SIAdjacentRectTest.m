//
//  ShiftIt_Tests.m
//  ShiftIt Tests
//
//  Created by Filip Krikava on 01/12/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import "SIAdjacentRect.h"

@interface SIAdjacentRectTest : SenTestCase
@end

@implementation SIAdjacentRectTest

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testTwoRectangles {
    NSRect a = NSMakeRect(5, 5, 5, 5);
    NSRect b = NSMakeRect(11, 6, 3, 3);
    NSRect c = NSMakeRect(11, 15, 3, 3);
    NSRect d = NSMakeRect(14, 11, 3, 3);
    NSRect e = NSMakeRect(14, 6, 3, 3);
    NSRect f = NSMakeRect(6, 13, 3, 3);
    NSRect g = NSMakeRect(2, 13, 3, 3);
    NSRect h = NSMakeRect(4, 17, 3, 3);
    NSRect i = NSMakeRect(1, 8, 3, 3);
    NSRect j = NSMakeRect(1, 4, 3, 3);
    NSRect k = NSMakeRect(6, 1, 3, 3);

    NSArray *rectValues = [NSArray arrayWithObjects:
            [SIRectWithValue rect:a withValue:@"A"],
            [SIRectWithValue rect:b withValue:@"B"],
            [SIRectWithValue rect:c withValue:@"C"],
            [SIRectWithValue rect:d withValue:@"D"],
            [SIRectWithValue rect:e withValue:@"E"],
            [SIRectWithValue rect:f withValue:@"F"],
            [SIRectWithValue rect:g withValue:@"G"],
            [SIRectWithValue rect:h withValue:@"H"],
            [SIRectWithValue rect:i withValue:@"I"],
            [SIRectWithValue rect:j withValue:@"J"],
            [SIRectWithValue rect:k withValue:@"K"],
            nil
    ];

    SIAdjacentRect *adjr = [SIAdjacentRect adjacentRect:rectValues];
    FMTDirection directions[] = {kRightDirection, kBottomDirection, kLeftDirection, kTopDirection};
    NSArray *path = [adjr buildDirectionalPath:directions fromValue:@"A"];

    STAssertEquals((NSUInteger)11, [path count], @"There is only one rectangle in right direction from A");
    NSLog(@"%@",path);
}

- (void)testDirectionalPath {
    NSRect a = NSMakeRect(5, 5, 5, 5);
    NSRect b = NSMakeRect(11, 6, 3, 3);

    NSArray *rectValues = [NSArray arrayWithObjects:
            [SIRectWithValue rect:a withValue:@"A"],
            [SIRectWithValue rect:b withValue:@"B"],
            nil
    ];

    SIAdjacentRect *adjr = [SIAdjacentRect adjacentRect:rectValues];

}

@end
