//
//  SimpleShiftItAction.m
//  ShiftIt
//
//  Created by Filip Krikava on 9/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "SimpleShiftItAction.h"
#import "FMTDefines.h"

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
    
    NSRect windowRect;
    if (![window getGeometry:&windowRect error:&cause]) {
        *error = SICreateErrorWithCause(kShiftItActionFaiureErrorCode, 
                                        cause,
                                        @"Unable to get window geometry");
        return NO;        
    }
    
    SIScreen *screen;
    if (![window getScreen:&screen error:&cause]) {
        *error = SICreateErrorWithCause(kShiftItActionFaiureErrorCode, 
                                        cause,
                                        @"Unable to get window screen");
        return NO;        
    }
    
    NSRect geometry = block_(windowRect, [screen size]);
    FMTLogDebug(@"Setting window geometry: %@", RECT_STR(geometry));
    
	// we need to translate from cocoa coordinates
	FMTLogDebug(@"Setting window geometry after readjusting the visiblity: %@", RECT_STR(geometry));	
    
    if (![window setGeometry:geometry error:&cause]) {
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
