//
//  FMTNSDictionary+Extras.m
//  ShiftIt
//
//  Created by Filip Krikava on 8/30/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "FMTNSDictionary+Extras.h"
#import "FMTDefines.h"

@implementation NSDictionary (FMTNSDictionaryExtras)

- (id) keyForObject:(id)object {
    FMTAssertNotNil(object);
    
    __block id theKey = nil;
    
    [self enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if (object == obj) {
            theKey = key;
            *stop = YES;
        }
    }];
    
    return theKey;
}

@end
