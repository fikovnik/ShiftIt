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

@implementation WindowGeometryShiftItAction

- (id) initWithIdentifier:(NSString *)identifier label:(NSString *)label uiTag:(NSInteger)uiTag block:(SimpleWindowGeometryChangeBlock)block {
    FMTAssertNotNil(identifier);
    FMTAssertNotNil(label);
    FMTAssertNotNil(block);
    
    if (![super initWithIdentifier:identifier label:label uiTag:uiTag]) {
        return nil;
    }
    
    block_ = block;
    
    return self;
}

- (BOOL) execute:(id<WindowContext>)windowContext error:(NSError **)error {
    FMTAssertNotNil(windowContext);
    FMTAssertNotNil(error);
    
    NSError *cause = nil;
    id<SIWindow> window = nil;
    BOOL flag = NO;

    if(![windowContext getFocusedWindow:&window error:&cause]) {
        *error = SICreateErrorWithCause(kShiftItActionFaiureErrorCode,
                                        cause,
                                        @"Unable to get active window");
        return NO;
    }

    if ([window respondsToSelector:@selector(getFullScreen:error:)]) {
        if (![window getFullScreen:&flag error:&cause]) {
            *error = SICreateErrorWithCause(kShiftItActionFaiureErrorCode,
                                            cause,
                                            @"Unable to get window fullScreen state");
        }
        if (flag) {
            *error = SICreateError(kShiftItActionFaiureErrorCode, @"Windows in fullscreen are not supported");
            return NO;
        }
    }

    NSRect currentGeometry;
    SIScreen *screen;
    if (![window getGeometry:&currentGeometry screen:&screen error:&cause]) {
        *error = SICreateErrorWithCause(kShiftItActionFaiureErrorCode,
                                        cause,
                                        @"Unable to get window geometry");
        return NO;        
    }
    if ([screen primary]) {
        // readjust the menu bar
        currentGeometry.origin.y -= GetMBarHeight();
    }
    FMTLogDebug(@"Current window geometry: %@", RECT_STR(currentGeometry));

    NSRect geometry = block_(currentGeometry, [screen size]);

    if (!NSEqualPoints(currentGeometry.origin, geometry.origin)) {
        if (![window canMove:&flag error:&cause]) {
            *error = SICreateErrorWithCause(kShiftItActionFaiureErrorCode,
                                            cause,
                                            @"Unable to find out if window is moveable");
        }
        if (!flag) {
            *error = SICreateError(kShiftItActionFaiureErrorCode, @"Window is not moveable");
            return NO;
        }
    }

    if (!NSEqualSizes(currentGeometry.size, geometry.size)) {
        if (![window canResize:&flag error:&cause]) {
            *error = SICreateErrorWithCause(kShiftItActionFaiureErrorCode,
                                            cause,
                                            @"Unable to find out if window is resizeable");
        }
        if (!flag) {
            *error = SICreateError(kShiftItActionFaiureErrorCode, @"Window is not resizeable");
            return NO;
        }
    }

    FMTLogDebug(@"New window geometry: %@", RECT_STR(geometry));
        
    if (![window setGeometry:geometry screen:screen error:&cause]) {
        *error = SICreateErrorWithCause(kShiftItActionFaiureErrorCode,
                                        cause,
                                        @"Unable to move window to %@", POINT_STR(geometry.origin));
        return NO;
    }
    
    // TODO: anchoring for descrete size windows
    // TODO: make sure window is always visible
    
    return YES;
}



@end
