//
//  SimpleShiftItAction.m
//  ShiftIt
//
//  Created by Filip Krikava on 9/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "SimpleShiftItAction.h"
#import "FMTDefines.h"

@interface SimpleShiftItAction ()

- (BOOL) shiftWindow_:(id<SIWindow>)window to:(NSRect)geometry error:(NSError **)error;

@end

@implementation SimpleShiftItAction

- (id) initWithIdentifier:(NSString *)identifier label:(NSString *)label uiTag:(NSInteger)uiTag block:(SimpleShiftItActionBlock)block {
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
    
    if(![windowContext getFocusedWindow:&window error:&cause]) {
        *error = SICreateErrorWithCause(kShiftItActionFaiureErrorCode, 
                                        cause,
                                        @"Unable to get active window");
        return NO;
    }
    
    // TODO: check resizability and moveability
    // TODO: check fullscreen
    
    NSRect geometry = block_([window geometry], [[window screen] size]);
    
    if(![self shiftWindow_:window to:geometry error:&cause]) {
        *error = SICreateErrorWithCause(kShiftItActionFaiureErrorCode, 
                                        cause,
                                        @"Unable to set active window geometry");
        return NO;        
    }
    
    return YES;
}

- (BOOL) shiftWindow_:(id<SIWindow>)window to:(NSRect)geometry error:(NSError **)error {
    FMTAssertNotNil(window);
    FMTLogDebug(@"Setting window geometry: %@", RECT_STR(geometry));
    
    NSRect windowRect = [window geometry];
    NSRect screenRect = [[window screen] screenRect];
    NSRect visibleScreenRect = [[window screen] visibleRect];
    
	// STEP 2: readjust adjust the visibility
	// the geometry is the new application window geometry relative to the screen originating at [0,0]
	// we need to shift it accordingly that is to the origin of the best fit screen (screenRect) and
	// take into account the visible area of such a screen - menu, dock, etc. which is in the visibleScreenRect
    // ************* FIXME !!!!!
	geometry.origin.x += screenRect.origin.x + visibleScreenRect.origin.x - screenRect.origin.x;
	geometry.origin.y += screenRect.origin.y + visibleScreenRect.origin.y - screenRect.origin.y;// - ([screen isPrimary] ? GetMBarHeight() : 0);
	
	// we need to translate from cocoa coordinates
	FMTLogDebug(@"Setting window geometry after readjusting the visiblity: %@", RECT_STR(geometry));	
    
    NSError *cause = nil;
	if (!NSEqualPoints(geometry.origin, windowRect.origin)) {
        if (![window moveTo:geometry.origin error:&cause]) {
            *error = SICreateErrorWithCause(kShiftItActionFaiureErrorCode, cause, @"Unable to move window to %@", POINT_STR(geometry.origin));
            return NO;
        }
    } else {
        FMTLogDebug(@"New origin and existing window origin are the same - no action");
    }
    
	if (!NSEqualSizes(geometry.size, windowRect.size)) {
        if (![window resizeTo:geometry.size error:&cause]) {
            *error = SICreateErrorWithCause(kShiftItActionFaiureErrorCode, cause, @"Unable to resize window to %@", SIZE_STR(geometry.size));
            return NO;
        }
    } else {
        FMTLogDebug(@"New size and existing window size are the same - no action");
    }
    
    // TODO: anchoring for descrete size windows
    // TODO: make sure window is always visible
    
    return YES;
}



@end
