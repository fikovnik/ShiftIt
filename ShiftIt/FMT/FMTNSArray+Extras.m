//
//  FMTNSArray+Extras.m
//  ShiftIt
//
//  Created by Filip Krikava on 9/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "FMTNSArray+Extras.h"

@implementation NSArray (FMTNSArrayExtras)

- (id) find:(BOOL (^)(id))predicate {
    for (id item in self) {
        if (predicate(item)) {
            return item;
        }
    }
    
    return nil;
}

- (NSUInteger)findIndex:(BOOL (^)(id))predicate {
    NSUInteger __block itemIndex = NSUIntegerMax;
    [self enumerateObjectsUsingBlock:^(id item, NSUInteger idx, BOOL *stop) {
        if (predicate(item)) {
            itemIndex = idx;
            *stop = YES;
        }
    }];

    return itemIndex;
}


- (NSArray *) filter:(BOOL (^)(id))predicate {
    NSMutableArray *res = [NSMutableArray array];

    for (id item in self) {
        if (predicate(item)) {
            [res addObject:item];
        }
    }
    
    return [NSArray arrayWithArray:res];
}

- (NSArray *) transform:(id(^)(id item))transformer {
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
