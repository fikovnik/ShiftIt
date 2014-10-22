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

@implementation NSArray (FMTNSArrayExtras)

- (id)find:(BOOL (^)(id))fun {
    for (id item in self) {
        if (fun(item)) {
            return item;
        }
    }

    return nil;
}

- (NSUInteger)indexWhere:(BOOL (^)(id))fun {
    for (int i = 0; i < [self count]; i++) {
        if (fun([self objectAtIndex:i])) return i;
    }

    return -1;
}

- (NSArray *)filter:(BOOL (^)(id))fun {
    NSMutableArray *tmp = [NSMutableArray array];

    for (id item in self) {
        if (fun(item)) {
            [tmp addObject:item];
        }
    }

    return [tmp copy];
}

- (NSArray *)map:(id(^)(id item))fun {
    NSMutableArray *tmp = [NSMutableArray arrayWithCapacity:[self count]];

    for (id item in self) {
        [tmp addObject:fun(item)];
    }

    return [tmp copy];
}

- (void)foreachWithStop:(bool (^)(id))fun {
    for (id item in self) {
        if (!fun(item)) break;
    }
}

- (void)foreach:(void (^)(id))fun {
    for (id item in self) {
        fun(item);
    }
}

@end
