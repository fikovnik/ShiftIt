//
//  Created by krikava on 01/12/11.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "SIAdjacentRect.h"
#import "FMT/FMT.h"

@implementation SIAdjacentRect

- (id)initWithRect:(NSArray *)rectangles forValues:(NSArray *)values {
    if (![super init]) {
        return nil;
    }

    FMTAssertNotNil(rectangles);
    FMTAssertNotNil(values);
    FMTAssert([rectangles count] == [values count], @"rectangles and values have to be of the same size");

    rectangles_ = [[NSDictionary dictionaryWithObjects:rectangles forKeys:values] retain];

    return self;
}

- (void)dealloc {
    [rectangles_ release];

    [super dealloc];
}

- (NSArray *)rectsInDirection:(SIDirection)direction {
    NSMutableArray *res = [NSMutableArray array];

    [rectangles_ enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {

        

    }];
    // compute the distance between the point and line
    // sort by the distance
    return nil;
}

+ (id)adjacentRect:(NSArray *)rectangles forValues:(NSArray *)values {
    return [[[SIAdjacentRect alloc] initWithRect:rectangles forValues:values] autorelease];
}


@end