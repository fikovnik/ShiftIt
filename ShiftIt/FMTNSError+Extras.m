//
//  FMTNSError+Extras.m
//  ShiftIt
//
//  Created by Filip Krikava on 9/7/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "FMTNSError+Extras.h"

@implementation NSError (FMTNSErrorExtras)

- (NSString *) fullDescription {
    NSError *error = self;
    NSMutableString *desc = [NSMutableString stringWithCapacity:100];
    
    [desc appendString:@"\nNSError stack trace:\n"];
    do {
        [desc appendFormat:@"%@:%d - %@", [error domain], [error code], [error localizedDescription]];
        error = [[error userInfo] objectForKey:NSUnderlyingErrorKey];
        if (error != nil) {
            [desc appendString:@"\n  Caused-by: "];
        }
    } while (error != nil);
    
    return [NSString stringWithString:desc];
}

@end
