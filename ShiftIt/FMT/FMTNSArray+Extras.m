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
