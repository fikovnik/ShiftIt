//
//  FMTNSArray+Extras.m
//  ShiftIt
//
//  Created by Filip Krikava on 9/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "FMTNSArray+Extras.h"

@implementation NSArray (FMTNSArrayExtras)

- (id) findFirst:(FMTPredicate)predicate {
    for (id item in self) {
        if (predicate(item)) {
            return item;
        }
    }
    
    return nil;
}

@end
