/*
ShiftIt: Resize windows with Hotkeys
Copyright (C) 2010  Aravind

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

#import <Carbon/Carbon.h>

#import "WindowSizer.h"
#import "ShiftIt.h"
#import "ShiftItAction.h"
#import "FMTDefines.h"

#define SIZE_STR(size) FMTStr(@"[%f %f]", (size).width, (size).height)
#define POINT_STR(point) FMTStr(@"[%f %f]", (point).x, (point).y)

@interface WindowSizer (Private)

- (void)chooseScreenForPosition_:(NSPoint *)sceenPosition size:(NSSize *)screenSize;
- (BOOL)getFocusedWindow_:(AXUIElementRef *)window position:(NSPoint *)position size:(NSSize *)size;
- (void)getScreenPosition_:(NSPoint *)screenPosition screenSize:(NSSize *)screenSize forWindowPosition:(NSPoint *)windowPosition windowSize:(NSSize *)windowSize;
- (void)getVisibleScreenPosition_:(NSPoint *)screenVisiblePosition visibleScreenSize:(NSSize *)visibleScreenSize forScreenPosition:(NSPoint *)screenPosition;

@end


@implementation WindowSizer

SINGLETON_BOILERPLATE(WindowSizer, sharedWindowSize);

- (id)init {
	if (![super init]) {
		return nil;
	}
	
	// get the accessibility object that provides access to system attributes.
	axSystemWideElement_ = AXUIElementCreateSystemWide();
	FMTAssertNotNil(axSystemWideElement_);
	
	return self;
}

// TODO: fix the error handling - propagate the AXError - not NSLog

- (void) shiftFocusedWindowUsing:(ShiftItAction *)action error:(NSError **)error {
	FMTAssertNotNil(action);

	NSPoint windowPosition;
	NSSize windowSize;
	NSPoint screenPosition;
	NSSize screenSize;
	NSPoint visibleScreenPosition;
	NSSize visibleScreenSize;
	AXUIElementRef window;

	if (![self getFocusedWindow_:&window position:&windowPosition size:&windowSize]) {		
        *error = SICreateError(@"Unable to get reference to the focused window", kNoFocusWindowRefErrorCode);
		return;
	}
	FMTDevLog(@"window position: %@, size: %@", POINT_STR(windowPosition), SIZE_STR(windowSize));
		
	[self getScreenPosition_:&screenPosition screenSize:&screenSize forWindowPosition:&windowPosition windowSize:&windowSize];
	FMTDevLog(@"screen position: %@, size: %@", POINT_STR(screenPosition), SIZE_STR(screenSize));

	int menuBarHeight = GetMBarHeight();

	[self getVisibleScreenPosition_:&visibleScreenPosition visibleScreenSize:&visibleScreenSize forScreenPosition:&screenPosition];
	FMTDevLog(@"visible screen position: %@, size: %@", POINT_STR(visibleScreenPosition), SIZE_STR(visibleScreenSize));

	// ShiftIt
	ShiftItFunctionRef actionFunction = [action action];
	actionFunction(&visibleScreenPosition, &visibleScreenSize, &windowPosition, &windowSize);
	FMTDevLog(@"ShiftIt to position: %@, size: %@", POINT_STR(windowPosition), SIZE_STR(windowSize));
	
	// adjust menu
	windowPosition.y = windowPosition.y + ((visibleScreenPosition.x == 0) ? menuBarHeight : 0);

	CFTypeRef positionRef = (CFTypeRef)(AXValueCreate(kAXValueCGPointType, (const void *)&windowPosition));
	CFTypeRef sizeRef = (CFTypeRef)(AXValueCreate(kAXValueCGSizeType, (const void *)&windowSize));
	
	if(AXUIElementSetAttributeValue((AXUIElementRef)window,(CFStringRef)NSAccessibilityPositionAttribute,(CFTypeRef*)positionRef) != kAXErrorSuccess){
        *error = SICreateError(@"AXError: Position cannot be changed", kPositionChangeFailedErrorCode);
		return;
	}
	
	if(AXUIElementSetAttributeValue((AXUIElementRef)window,(CFStringRef)NSAccessibilitySizeAttribute,(CFTypeRef*)sizeRef) != kAXErrorSuccess){
        *error = SICreateError(@"AXError: Size cannot be modified", kSizeChangeFailedErrorCode);
		return;
	}	
}

- (BOOL)getFocusedWindow_:(AXUIElementRef *)window position:(NSPoint *)position size:(NSSize *)size {
	FMTAssertNotNil(position);
	FMTAssertNotNil(size);
	
	//get the focused application
	AXUIElementRef focusedAppRef = nil;
	AXError axerror = AXUIElementCopyAttributeValue(axSystemWideElement_,
													(CFStringRef) kAXFocusedApplicationAttribute,
													(CFTypeRef *) &focusedAppRef);
	
	if (axerror != kAXErrorSuccess) {
		NSLog(@"AXError: Unable to get focused application");		
		return NO;
	}
	FMTAssertNotNil(focusedAppRef);
	
	//get the focused window
	AXUIElementRef focusedWindowRef = nil;
	axerror = AXUIElementCopyAttributeValue((AXUIElementRef)focusedAppRef,
											(CFStringRef)NSAccessibilityFocusedWindowAttribute,
											(CFTypeRef*)&focusedWindowRef);
	if (axerror != kAXErrorSuccess) {
		NSLog(@"AXError: Unable to get focused window");		
		return NO;
	}
	FMTAssertNotNil(focusedWindowRef);
	*window = focusedWindowRef;
	
	//get the position
	CFTypeRef positionRef;
	axerror = AXUIElementCopyAttributeValue((AXUIElementRef)focusedWindowRef,(CFStringRef)NSAccessibilityPositionAttribute,(CFTypeRef*)&positionRef);
	if (axerror != kAXErrorSuccess) {
		FMTDevLog(@"AXError: Unable to get focused window position");		
		return NO;
	}
	FMTAssertNotNil(positionRef);
	if(AXValueGetType(positionRef) == kAXValueCGPointType) {
		AXValueGetValue(positionRef, kAXValueCGPointType, (void*)position);
	} else {
		NSLog(@"AXError: Unable to extract position");		
		return NO;
	}
	
	//get the focused size
	CFTypeRef sizeRef;
	axerror = AXUIElementCopyAttributeValue((AXUIElementRef)focusedWindowRef,(CFStringRef)NSAccessibilitySizeAttribute,(CFTypeRef*)&sizeRef);
	if (axerror != kAXErrorSuccess) {
		NSLog(@"AXError: Unable to get focused window size");		
		return NO;
	}
	FMTAssertNotNil(sizeRef);
	if(AXValueGetType(sizeRef) == kAXValueCGSizeType) {
		AXValueGetValue(sizeRef, kAXValueCGSizeType, (void*)size);
	} else {
		NSLog(@"AXError: Unable to extract position");		
		return NO;
	}
	
	return YES;
}

- (void)getScreenPosition_:(NSPoint *)screenPosition screenSize:(NSSize *)screenSize forWindowPosition:(NSPoint *)windowPosition windowSize:(NSSize *)windowSize  {
	FMTAssertNotNil(windowPosition);
	FMTAssertNotNil(windowSize);
	FMTAssertNotNil(screenPosition);
	FMTAssertNotNil(screenSize);

	// TODO: following only works with assumption that a window can be maximum on an intersection of two displays
    CGDirectDisplayID tempId[2];
    CGDisplayCount tempCount;
    CGError error = CGGetDisplaysWithRect(CGRectMake(windowPosition->x, windowPosition->y, windowSize->width, windowSize->height), 2, tempId, &tempCount);
    if(error == kCGErrorSuccess){
        CGRect screenBounds = CGDisplayBounds(tempId[0]);
        if (tempCount == 1) {
            screenPosition->x = screenBounds.origin.x;
            screenPosition->y = screenBounds.origin.y;
            screenSize->width = screenBounds.size.width;
            screenSize->height = screenBounds.size.height;
        } else if (tempCount == 2) {
            CGRect screenBounds1 = CGDisplayBounds(tempId[1]);
            int screenChosen = 0;
            int delta = abs(screenBounds.origin.x - (windowPosition->x+windowSize->width));
            int delta2 = 0;
            if(delta > screenBounds.size.width){
                delta = abs(windowPosition->x - (screenBounds.origin.x+screenBounds.size.width));
                delta2 = abs(windowPosition->x+windowSize->width - screenBounds1.origin.x);
            }else {
                delta2 = abs(windowPosition->x - (screenBounds1.origin.x+screenBounds1.size.width));
            }
            if (delta2> delta) {
                screenChosen = 1;
            }
            if(screenChosen == 0){
                screenPosition->x = screenBounds.origin.x;
                screenPosition->y = screenBounds.origin.y;
                screenSize->width = screenBounds.size.width;
                screenSize->height = screenBounds.size.height;
            }else {
                screenPosition->x = screenBounds1.origin.x;
                screenPosition->y = screenBounds1.origin.y;
                screenSize->width = screenBounds1.size.width;
                screenSize->height = screenBounds1.size.height;
            }
        }       
    }
}

- (void)getVisibleScreenPosition_:(NSPoint *)visibleScreenPosition visibleScreenSize:(NSSize *)visibleScreenSize forScreenPosition:(NSPoint *)screenPosition {
	FMTAssertNotNil(visibleScreenPosition);
	FMTAssertNotNil(visibleScreenSize);
	FMTAssertNotNil(screenPosition);
	
	NSArray *screens = [NSScreen screens];

	for(int i = 0; i < [screens count]; i++) {
		NSScreen * screen = (NSScreen*)[screens objectAtIndex:i];
		if ([screens count] == 1 || screen.frame.origin.x == screenPosition->x) {
			NSPoint origin = screen.frame.origin;
			visibleScreenPosition->x = origin.x;
			visibleScreenPosition->y = origin.y;
			
			NSSize size = [screen visibleFrame].size;
			visibleScreenSize->width = size.width;
			visibleScreenSize->height = size.height;
			break;
		}
	}
}

@end
