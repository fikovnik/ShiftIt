//
//  FMTNSArray+Extras.h
//  ShiftIt
//
//  Created by Filip Krikava on 9/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef BOOL(^FMTEachCallback)(id item);

@interface NSArray (FMTNSArrayExtras)

- (id) find:(BOOL (^)(id))predicate;
- (NSUInteger) findIndex:(BOOL (^)(id))predicate;
- (NSArray *) filter:(BOOL (^)(id))predicate;
- (NSArray *) transform:(id(^)(id item))transformer;
- (void) each:(FMTEachCallback)callback;

@end
