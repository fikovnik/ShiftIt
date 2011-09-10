//
//  FMTNSArray+Extras.h
//  ShiftIt
//
//  Created by Filip Krikava on 9/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef BOOL(^FMTPredicate)(id item);

@interface NSArray (FMTNSArrayExtras)

- (id) findFirst:(FMTPredicate)predicate;

@end
