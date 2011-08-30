//
//  FMTNSDate+Extras.m
//  ShiftIt
//
//  Created by Filip Krikava on 8/31/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "FMTNSDate+Extras.h"

@implementation NSDate (FMTNSDateExtras)

- (NSDateComponents *) dateComponents {
    NSCalendar *cal = [NSCalendar currentCalendar];
    return [cal components:(NSYearCalendarUnit 
                            | NSMonthCalendarUnit 
                            |  NSDayCalendarUnit 
                            | NSHourCalendarUnit 
                            | NSMinuteCalendarUnit) fromDate:self];
}

- (NSString *) stringWithFormat:(NSString *)format {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:format];

    NSString *string = [dateFormatter stringFromDate:self];
    
    [dateFormatter release];
    
    return string;
}

@end
