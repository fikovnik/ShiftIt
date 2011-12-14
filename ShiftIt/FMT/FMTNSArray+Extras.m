//
//  FMTNSArray+Extras.m
//  ShiftIt
//
//  Created by Filip Krikava on 9/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "FMTNSArray+Extras.h"

@implementation NSArray (FMTNSArrayExtras)

- (id) filterFirst:(FMTPredicate)predicate {
    for (id item in self) {
        if (predicate(item)) {
            return item;
        }
    }
    
    return nil;
}

- (NSArray *) filter:(FMTPredicate)predicate {
    NSMutableArray *res = [NSMutableArray array];

    for (id item in self) {
        if (predicate(item)) {
            [res addObject:item];
        }
    }
    
    return [NSArray arrayWithArray:res];
}

- (NSArray *) transform:(FMTItemTransformer)transformer {
    NSMutableArray *res = [NSMutableArray arrayWithCapacity:[self count]];
 
    for (id item in self) {
        [res addObject:transformer(item)];
    }
    
    return [NSArray arrayWithArray:res];
}

- (void) each:(FMTEachCallback)callback {
    for (id item in self) {
        if (!callback(item)) {
            break;
        }
    }
}

@end
