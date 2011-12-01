//
//  SimpleShiftItAction.m
//  ShiftIt
//
//  Created by Filip Krikava on 9/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Carbon/Carbon.h>
#import "WindowGeometryShiftItAction.h"
#import "FMTDefines.h"
#import "ShiftIt.h"

@implementation AbstractWindowGeometryShiftItAction

- (BOOL) execute:(id<WindowContext>)windowContext error:(NSError **)error {
    FMTAssertNotNil(windowContext);
    FMTAssertNotNil(error);
    
    NSError *cause = nil;
    id<SIWindow> window = nil;
    BOOL flag = NO;

    if(![windowContext getFocusedWindow:&window error:&cause]) {
        *error = SICreateErrorWithCause(kShiftItActionFailureErrorCode,
                                        cause,
                                        @"Unable to get active window");
        return NO;
    }

    if ([window respondsToSelector:@selector(getFullScreen:error:)]) {
        if (![window getFullScreen:&flag error:&cause]) {
            *error = SICreateErrorWithCause(kShiftItActionFailureErrorCode,
                                            cause,
                                            @"Unable to get window fullScreen state");
        }
        if (flag) {
            *error = SICreateError(kShiftItActionFailureErrorCode, @"Windows in fullscreen are not supported");
            return NO;
        }
    }

    NSRect currentGeometry;
    SIScreen *screen;
    if (![window getGeometry:&currentGeometry screen:&screen error:&cause]) {
        *error = SICreateErrorWithCause(kShiftItActionFailureErrorCode,
                                        cause,
                                        @"Unable to get window geometry");
        return NO;        
    }

    FMTLogInfo(@"Current window geometry: %@", RECT_STR(currentGeometry));

    NSSize screenSize = [screen size];
    NSRect geometry = [self shiftWindowRect:currentGeometry screenSize:screenSize withContext:windowContext];

    if (!NSEqualPoints(currentGeometry.origin, geometry.origin)) {
        if (![window canMove:&flag error:&cause]) {
            *error = SICreateErrorWithCause(kShiftItActionFailureErrorCode,
                                            cause,
                                            @"Unable to find out if window is moveable");
        }
        if (!flag) {
            *error = SICreateError(kShiftItActionFailureErrorCode, @"Window is not moveable");
            return NO;
        }
    }

    if (!NSEqualSizes(currentGeometry.size, geometry.size)) {
        if (![window canResize:&flag error:&cause]) {
            *error = SICreateErrorWithCause(kShiftItActionFailureErrorCode,
                                            cause,
                                            @"Unable to find out if window is resizeable");
        }
        if (!flag) {
            *error = SICreateError(kShiftItActionFailureErrorCode, @"Window is not resizeable");
            return NO;
        }
    }

    FMTLogInfo(@"New window geometry: %@", RECT_STR(geometry));

    if (![window setGeometry:geometry screen:screen error:&cause]) {
        *error = SICreateErrorWithCause(kShiftItActionFailureErrorCode,
                                        cause,
                                        @"Unable to move window to %@", POINT_STR(geometry.origin));
        return NO;
    }

    // TODO: only when it is active
    if (![windowContext anchorWindow:window error:&cause]) {
        *error = SICreateErrorWithCause(kShiftItActionFailureErrorCode,
                                        cause,
                                        @"Unable to anchor window");
        return NO;
    }
    
    // TODO: make sure window is always visible
    
    return YES;
}

@end

@implementation WindowGeometryShiftItAction

- (id) initWithBlock:(SimpleWindowGeometryChangeBlock)block {
    FMTAssertNotNil(block);
    
    if (![super init]) {
        return nil;
    }
    
    block_ = block;
    
    return self;
}

- (NSRect)shiftWindowRect:(NSRect)windowRect screenSize:(NSSize)screenSize withContext:(id<WindowContext>)windowContext {
    return block_(windowRect, screenSize);
}

@end