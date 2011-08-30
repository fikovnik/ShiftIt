//
//  FMTNSDate+Extras.h
//  ShiftIt
//
//  Created by Filip Krikava on 8/31/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (FMTNSDate_Extras)

- (NSDateComponents *) dateComponents;
- (NSString *) stringWithFormat:(NSString *)format;

@end
