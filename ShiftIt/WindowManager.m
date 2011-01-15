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

#import "WindowManager.h"
#import "ShiftIt.h"
#import "ShiftItAction.h"
#import "FMTDefines.h"

#define RECT_STR(rect) FMTStr(@"[%f %f] [%f %f]", (rect).origin.x, (rect).origin.y, (rect).size.width, (rect).size.height)
#define COCOA_TO_SCREEN_COORDINATES(rect) (rect).origin.y = [[NSScreen primaryScreen] frame].size.height - (rect).size.height - (rect).origin.y

// reference to the carbon GetMBarHeight() function
extern short GetMBarHeight(void);

// AXUI helpers
// TODO: convert to NSString
static const char *const kAXUIErrorMessages_[] = {
	"AXError: Unable to get active application",
	"AXError: Unable to get active window",
	"AXError: Unable to get active window position",
	"AXError: Unable to extract position",
	"AXError: Unable to get focused window size",
	"AXError: Unable to extract position",
	"AXError: Position cannot be changed",
	"AXError: Size cannot be modified"
};

#define AXUIGetErrorMessage(idx) kAXUIErrorMessages_[-idx-1]

int AXUIGetFocusedWindowId(WindowId *windowId, AXUIElementRef axSystemWideElement);
void AXUIFreeWindowId(WindowId windowId);
int AXUIGetWindowGeometry(WindowId windowId, NSPoint *origin, NSSize *size);
int AXUISetWindowPosition(WindowId windowId, NSPoint origin);
int AXUISetWindowSize(WindowId windowId, NSSize size);

#pragma mark NSScreen Private Additions

@interface NSScreen (Private)

+ (NSScreen *)primaryScreen;
- (BOOL)isPrimary;

@end

@implementation NSScreen (Private)

+ (NSScreen *)primaryScreen {
	return [[NSScreen screens] objectAtIndex:0];
}

- (BOOL)isPrimary {
	return self == [NSScreen primaryScreen];
}

@end

#pragma mark Screen Implementation

@interface Screen ()

@property (readonly) NSRect screenFrame_;
@property (readonly) NSRect visibleFrame_;

@end

@implementation Screen

@dynamic size;
@synthesize primary = primary_;

@synthesize screenFrame_;
@synthesize visibleFrame_;

- (id) initWithNSScreen:(NSScreen *)screen {
	FMTAssertNotNil(screen);
	
	if (![super init]) {
		return nil;
	}
	
	// screen coordinates of the best fit window
	screenFrame_ = [screen frame];
	COCOA_TO_SCREEN_COORDINATES(screenFrame_);
	
	// visible screen coordinates of the best fit window
	// the visible screen denotes some inner rect of the screen frame
	// which is visible - not occupied by menu bar or dock
	visibleFrame_ = [screen visibleFrame];
	COCOA_TO_SCREEN_COORDINATES(visibleFrame_);
	
	primary_ = [screen isPrimary];
	
	return self;
}

- (NSSize) size {
	return visibleFrame_.size;
}

@end

#pragma mark Window Implementation

@interface Window ()

@property (readonly) WindowId windowId_;

@end

@implementation Window

@dynamic origin;
@dynamic size;
@synthesize screen = screen_;

@synthesize windowId_;

- (id) initWithId:(WindowId)windowId rect:(NSRect)rect screen:(Screen *)screen {
	FMTAssertNotNil(windowId);
	FMTAssertNotNil(screen);
	
	if (![super init]) {
		return nil;
	}
	
	windowId_ = windowId;
	rect_ = rect;
	screen_ = [screen retain];
	
	return self;
}

- (void) dealloc {
	CFRelease(windowId_);
	[screen_ release];
	
	[super dealloc];
}

- (NSPoint) origin {
	return rect_.origin;
}

- (NSSize) size {
	return rect_.size;
}

@end

#pragma mark WindowManager Implementation

@interface WindowManager ()

- (NSScreen *)chooseScreenForWindow_:(NSRect)windowRect;

@end

@implementation WindowManager

- (id)init {
	if (![super init]) {
		return nil;
	}
	
	axSystemWideElement_ = AXUIElementCreateSystemWide();
	// here is the assert for purpose because the app should not have gone 
	// that far in execution if the AX api is not available
	FMTAssertNotNil(axSystemWideElement_);
	
	return self;
}

- (void) dealloc {
	CFRelease(axSystemWideElement_);
	
	[super dealloc];
}

- (void) focusedWindow:(Window **)window error:(NSError **)error {
	WindowId windowId;
	int ret;
	
	// first try to get the window using accessibility API
	if ((ret = AXUIGetFocusedWindowId(&windowId, axSystemWideElement_)) != 0) {
		*error = CreateError(kUnableToGetActiveWindowErrorCode, FMTStrc(AXUIGetErrorMessage(ret)), nil);
		return;		
	}
	
	NSRect windowRect;
	if ((ret = AXUIGetWindowGeometry(windowId, &windowRect.origin, &windowRect.size)) != 0) {
		*error = CreateError(kUnableToGetWindowGeometryErrorCode, FMTStrc(AXUIGetErrorMessage(ret)), nil);
		return;			
	}
	
	NSScreen *nsscreen = [self chooseScreenForWindow_:windowRect];
	FMTAssertNotNil(nsscreen);
	Screen *screen = [[Screen alloc] initWithNSScreen:nsscreen];
	
	*window = [[Window alloc] initWithId:windowId rect:windowRect screen:screen];
}

- (void) moveWindow:(Window *)window origin:(NSPoint)origin error:(NSError **)error {
	FMTAssertNotNil(window);
	
	// readjust adjust the visibility
	// the shiftedRect is the new application window geometry relative to the screen originating at [0,0]
	// we need to shift it accordingly that is to the origin of the best fit screen (screenRect) and
	// take into account the visible area of such a screen - menu, dock, etc. which is in the visibleScreenRect
	origin.x += [[window screen] visibleFrame_].origin.x;
	origin.y += [[window screen] visibleFrame_].origin.y;
	
	FMTDevLog(@"adjusting position to %dx%d", origin.x, origin.y);
	int ret;
	
	if ((ret = AXUISetWindowPosition([window windowId_], origin)) != 0) {
		*error = CreateError(kUnableToChangeWindowPositionErrorCode, FMTStrc(AXUIGetErrorMessage(ret)), nil);
		return;
	}	
}

- (void) resizeWindow:(Window *)window size:(NSSize)size error:(NSError **)error {
	FMTAssertNotNil(window);
		
	FMTDevLog(@"adjusting size to %dx%d", size);
	int ret;
	
	if ((ret = AXUISetWindowSize([window windowId_], size)) != 0) {
		*error = CreateError(kUnableToChangeWindowSizeErrorCode, FMTStrc(AXUIGetErrorMessage(ret)), nil);
		return;
	}	
}

- (void) shiftWindow:(Window *)window origin:(NSPoint)origin size:(NSSize)size error:(NSError **)error {
	FMTAssertNotNil(window);

	NSError *localError = nil;
	
	[self moveWindow:window origin:origin error:&localError];
	HANDLE_WM_ERROR(error,localError);
	
	[self resizeWindow:window size:size error:&localError];
	HANDLE_WM_ERROR(error,localError);
}


/**
 * Chooses the best screen for the given window rect (screen coord).
 *
 * For each screen it computes the intersecting rectangle and its size. 
 * The biggest is the screen where is the most of the window hence the best fit.
 */
- (NSScreen *)chooseScreenForWindow_:(NSRect)windowRect {
	// TODO: rename intgersect
	// TODO: all should be ***Rect
	
	NSScreen *fitScreen = [NSScreen mainScreen];
	float maxSize = 0;
	
	for (NSScreen *screen in [NSScreen screens]) {
		NSRect screenRect = [screen frame];
		// need to convert coordinates
		COCOA_TO_SCREEN_COORDINATES(screenRect);
		 
		NSRect intersectRect = NSIntersectionRect(screenRect, windowRect);

		if (intersectRect.size.width > 0 ) {
			float size = intersectRect.size.width * intersectRect.size.height;
			if (size > maxSize) {
				fitScreen = screen;
				maxSize = size;
			}
		}
	}

	return fitScreen;
}

@end

#pragma mark AXUI utilities

int AXUIGetFocusedWindowId(WindowId *windowId, AXUIElementRef axSystemWideElement) {	
	//get the focused application
	AXUIElementRef focusedAppRef = nil;
	
	AXError ret = AXUIElementCopyAttributeValue(axSystemWideElement,
													(CFStringRef) kAXFocusedApplicationAttribute,
													(CFTypeRef *) &focusedAppRef);	
	if (ret != kAXErrorSuccess) {
		return -1;
	}
	
	FMTAssertNotNil(focusedAppRef);
	
	//get the focused window
	AXUIElementRef focusedWindowRef = nil;
	
	ret = AXUIElementCopyAttributeValue((AXUIElementRef)focusedAppRef,
											(CFStringRef)NSAccessibilityFocusedWindowAttribute,
											(CFTypeRef*)&focusedWindowRef);
	CFRelease(focusedAppRef);
	
	if (ret != kAXErrorSuccess) {
		return -2;
	}
	
	*windowId = (WindowId)focusedWindowRef;
	
	return 0;
}

void AXUIFreeWindowId(WindowId windowId) {
	FMTAssertNotNil(windowId);
	
	CFRelease((CFTypeRef) windowId);
}

int AXUIGetWindowGeometry(WindowId windowId, NSPoint *origin, NSSize *size) {
	FMTAssertNotNil(windowId);
	FMTAssertNotNil(origin);
	FMTAssertNotNil(size);
		
	//get the position
	CFTypeRef originRef;
	
	AXError ret = AXUIElementCopyAttributeValue((AXUIElementRef)windowId,(CFStringRef)NSAccessibilityPositionAttribute,(CFTypeRef*)&originRef);
	if (ret != kAXErrorSuccess) {
		return -3;
	}
	
	FMTAssertNotNil(originRef);
	if(AXValueGetType(originRef) == kAXValueCGPointType) {
		AXValueGetValue(originRef, kAXValueCGPointType, (void*)origin);
	} else {
		CFRelease(originRef);
		
		return -4;
	}
	CFRelease(originRef);
	
	//get the focused size
	CFTypeRef sizeRef;
	
	ret = AXUIElementCopyAttributeValue((AXUIElementRef)windowId,(CFStringRef)NSAccessibilitySizeAttribute,(CFTypeRef*)&sizeRef);
	if (ret != kAXErrorSuccess) {
		return -5;
	}
	
	FMTAssertNotNil(sizeRef);
	if(AXValueGetType(sizeRef) == kAXValueCGSizeType) {
		AXValueGetValue(sizeRef, kAXValueCGSizeType, (void*)size);
	} else {
		CFRelease(sizeRef);
		
		return -6;
	}
	CFRelease(sizeRef);
	
	return 0;
}

int AXUISetWindowPosition(WindowId windowId, NSPoint origin) {
	FMTAssertNotNil(windowId);
	
	CFTypeRef originRef = (CFTypeRef)(AXValueCreate(kAXValueCGPointType, (const void *)&origin));
	
	AXError ret = AXUIElementSetAttributeValue((AXUIElementRef)windowId,(CFStringRef)NSAccessibilityPositionAttribute,(CFTypeRef*)originRef);
	
	CFRelease(originRef);

	if(ret != kAXErrorSuccess){
		return -7;
	} else {
		return 0;
	}	
}

int AXUISetWindowSize(WindowId windowId, NSSize size) {
	FMTAssertNotNil(windowId);
	
	CFTypeRef sizeRef = (CFTypeRef)(AXValueCreate(kAXValueCGSizeType, (const void *)&size));
	
	AXError ret = AXUIElementSetAttributeValue((AXUIElementRef)windowId,(CFStringRef)NSAccessibilitySizeAttribute,(CFTypeRef*)sizeRef);
	
	CFRelease(sizeRef);

	if(ret != kAXErrorSuccess){
		return -8;
	} else {
		return 0;
	}	
}