//
//  SIWindowInfo.h
//  ShiftIt
//
//  Created by Filip Krikava on 12/14/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

@interface SIWindowInfo : NSObject {
@private
    pid_t pid_;
    CGWindowID wid_;
    NSRect rect_;
}

@property (readonly) pid_t pid;
@property (readonly) CGWindowID wid;
@property (readonly) NSRect rect;

+ (SIWindowInfo *) windowInfoFromCGWindowInfoDictionary:(NSDictionary *)windowInfo;

@end