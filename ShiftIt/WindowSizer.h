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
	AXUIElementRef _focusedApp;
	CFTypeRef _focusedWindow;
	CFTypeRef _position;
	CFTypeRef _size;
	NSSize _screenRectSize;
	NSRect _startPosition;
	NSSize _fullScreenSize;
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
