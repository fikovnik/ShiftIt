//
//  WindowSizer.h
//  ShiftIt
//
//  Created by Aravindkumar Rajendiran on 10-02-13.
//  Copyright 2010 Grapewave. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface WindowSizer : NSObject {
    AXUIElementRef	_systemWideElement;
    CFTypeRef _focusedWindow;
    NSSize _screenSize;
    NSSize _screenVisibleSize;
    NSPoint _screenVisiblePosition;
    NSPoint _screenPosition;
    NSPoint _windowPosition;
    NSSize _windowSize;
}

-(IBAction)shiftToLeftHalf:(id)sender;
-(IBAction)shiftToRightHalf:(id)sender;
-(IBAction)shiftToBottomHalf:(id)sender;
-(IBAction)shiftToTopHalf:(id)sender;
-(IBAction)shiftToTopRight:(id)sender;
-(IBAction)shiftToTopLeft:(id)sender;
-(IBAction)shiftToBottomLeft:(id)sender;
-(IBAction)shiftToBottomRight:(id)sender;
-(IBAction)fullScreen:(id)sender;
-(IBAction)shiftToCenter:(id)sender;

@end
