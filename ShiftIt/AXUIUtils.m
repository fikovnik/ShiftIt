/*
 ShiftIt: Resize windows with Hotkeys
 Copyright (C) 2010  Filip Krikava
 
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

#import <Foundation/Foundation.h>

#import "AXUIUtils.h"
#import "FMTDefines.h"

static const char *const kErrorMessages_[] = {
	"AXError: Unable to get active application",
	"AXError: Unable to get active window",
	"AXError: Unable to get active window position",
	"AXError: Unable to extract position",
	"AXError: Unable to get focused window size",
	"AXError: Unable to extract position",
	"AXError: Position cannot be changed",
	"AXError: Size cannot be modified"
};

static int kErrorMessageCount_ = sizeof(kErrorMessages_)/sizeof(kErrorMessages_[0]);

// TODO: assert
int AXUISetWindowGeometry(void *window, int x, int y, unsigned int width, unsigned int height) {
	FMTAssertNotNil(window);
	
	NSPoint position = {x, y};
	CFTypeRef positionRef = (CFTypeRef)(AXValueCreate(kAXValueCGPointType, (const void *)&position));
	if(AXUIElementSetAttributeValue((AXUIElementRef)window,(CFStringRef)NSAccessibilityPositionAttribute,(CFTypeRef*)positionRef) != kAXErrorSuccess){
		CFRelease(positionRef);
		return -7;
	}
	CFRelease(positionRef);
	
	NSSize size = {width, height};
	CFTypeRef sizeRef = (CFTypeRef)(AXValueCreate(kAXValueCGSizeType, (const void *)&size));
	if(AXUIElementSetAttributeValue((AXUIElementRef)window,(CFStringRef)NSAccessibilitySizeAttribute,(CFTypeRef*)sizeRef) != kAXErrorSuccess){
		CFRelease(sizeRef);
		return -8;
	}		
	CFRelease(sizeRef);
	
	return 0;
}

void AXUIFreeWindowRef(void *window) {
	FMTAssertNotNil(window);

	CFRelease((CFTypeRef) window);
}

const char *AXUIGetErrorMessage(int code) {
	FMTAssert(code < 0 && code > -kErrorMessageCount_, @"error code must be %d < code < 0", -kErrorMessageCount_);
	
	return kErrorMessages_[-code-1];
}

int AXUIGetActiveWindowGeometry(void **activeWindow, int *x, int *y, unsigned int *width, unsigned int *height) {
	FMTAssertNotNil(x);
	FMTAssertNotNil(y);
	FMTAssertNotNil(width);
	FMTAssertNotNil(height);
	
	AXUIElementRef systemElementRef = AXUIElementCreateSystemWide();
	// here is the assert for purpose because the app should not have gone 
	// that far in execution if the AX api is not available
	FMTAssertNotNil(systemElementRef);

	//get the focused application
	AXUIElementRef focusedAppRef = nil;
	AXError axerror = AXUIElementCopyAttributeValue(systemElementRef,
													(CFStringRef) kAXFocusedApplicationAttribute,
													(CFTypeRef *) &focusedAppRef);
	CFRelease(systemElementRef);
	
	if (axerror != kAXErrorSuccess) {
		return -1;
	}
	FMTAssertNotNil(focusedAppRef);
	
	//get the focused window
	AXUIElementRef focusedWindowRef = nil;
	axerror = AXUIElementCopyAttributeValue((AXUIElementRef)focusedAppRef,
											(CFStringRef)NSAccessibilityFocusedWindowAttribute,
											(CFTypeRef*)&focusedWindowRef);
	CFRelease(focusedAppRef);
	if (axerror != kAXErrorSuccess) {
		return -2;
	}
	FMTAssertNotNil(focusedWindowRef);
	*activeWindow = (void *) focusedWindowRef;
	
	//get the position
	CFTypeRef positionRef;
	NSPoint position;
	axerror = AXUIElementCopyAttributeValue((AXUIElementRef)focusedWindowRef,(CFStringRef)NSAccessibilityPositionAttribute,(CFTypeRef*)&positionRef);
	if (axerror != kAXErrorSuccess) {
		CFRelease(focusedWindowRef);

		return -3;
	}
	FMTAssertNotNil(positionRef);
	if(AXValueGetType(positionRef) == kAXValueCGPointType) {
		AXValueGetValue(positionRef, kAXValueCGPointType, (void*)&position);
		*x = (int) position.x;
		*y = (int) position.y;
	} else {
		CFRelease(focusedWindowRef);
		CFRelease(positionRef);
		
		return -4;
	}
	CFRelease(positionRef);
	
	//get the focused size
	CFTypeRef sizeRef;
	NSSize size;
	axerror = AXUIElementCopyAttributeValue((AXUIElementRef)focusedWindowRef,(CFStringRef)NSAccessibilitySizeAttribute,(CFTypeRef*)&sizeRef);
	if (axerror != kAXErrorSuccess) {
		CFRelease(focusedWindowRef);

		return -5;
	}
	FMTAssertNotNil(sizeRef);
	if(AXValueGetType(sizeRef) == kAXValueCGSizeType) {
		AXValueGetValue(sizeRef, kAXValueCGSizeType, (void*)&size);
		*width = (unsigned int) size.width;
		*height = (unsigned int) size.height;
	} else {
		CFRelease(focusedWindowRef);
		CFRelease(sizeRef);

		return -6;
	}
	CFRelease(sizeRef);
	
	return 0;
}
