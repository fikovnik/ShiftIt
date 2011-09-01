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
    SIWindow *window = nil;
    
    if(![windowContext getFocusedWindow:&window error:&cause]) {
        *error = SICreateErrorWithCause(@"Unable to get active window", 
                                        kShiftItActionFaiureErrorCode, 
                                        cause);
        return NO;
    }
    
    // TODO: check resizability and moveability
    // TODO: check fullscreen
    
    NSRect newGeometry = block_([window geometry], [[window screen] size]);
    
    if(![windowContext setWindow:window geometry:newGeometry error:&cause]) {
        *error = SICreateErrorWithCause(@"Unable to set active window geometry", 
                                        kShiftItActionFaiureErrorCode, 
                                        cause);
        return NO;        
    }
    
    return YES;
}

@end
