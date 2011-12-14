//
//  X11WindowDriver.h
//  ShiftIt
//
//  Created by Filip Krikava on 9/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

// make sure this does not collide with the Cursor from Carbon/Cocoa
#define Cursor X11Cursor
#import <X11/Xlib.h>
#import <X11/Xatom.h>
#import <X11/Xutil.h>
#undef Cursor

#import <Foundation/Foundation.h>
#import "SIWindowDriver.h"

@interface X11WindowDriver : NSObject<SIWindowDriver> {

}

- (id)initWithError:(NSError **)error;

@end
