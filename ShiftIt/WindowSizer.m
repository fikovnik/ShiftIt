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
#import "AXUIUtils.h"
#import "X11Utils.h"

#define RECT_STR(rect) FMTStr(@"[%f %f] [%f %f]", (rect).origin.x, (rect).origin.y, (rect).size.width, (rect).size.height)

@interface NSScreen (Private)

+ (NSScreen *)primaryScreen;
- (BOOL)hasMenuBar;

@end

@implementation NSScreen (Private)

+ (NSScreen *)primaryScreen {
	return [[NSScreen screens] objectAtIndex:0];
}

- (BOOL)hasMenuBar {
	return self == [NSScreen primaryScreen];
}

@end

#define COCOA_TO_SCREEN_COORDINATES(rect) (rect).origin.y = [[NSScreen primaryScreen] frame].size.height - (rect).size.height; \
										  (rect).size.height -= (rect).origin.y 

@interface WindowSizer (Private)

- (NSScreen *)chooseScreenForWindow_:(NSRect)windowRect;

@end


@implementation WindowSizer

SINGLETON_BOILERPLATE(WindowSizer, sharedWindowSize);

// TODO: remove
- (id)init {
	if (![super init]) {
		return nil;
	}
	
	return self;
}

// TODO: fix the error handling - propagate the AXError - not NSLog - strerr
- (void) shiftFocusedWindowUsing:(ShiftItAction *)action error:(NSError **)error {
	FMTAssertNotNil(action);
	
#ifdef X11
	// following will make the X11 reference coordinate system
	// X11 coordinates starts at the very top left corner of the most top left window
	// basically it is a union of all screens with the beginning at the top left
	NSRect X11Ref = [[NSScreen primaryScreen] frame];
	for (NSScreen *screen in [NSScreen screens]) {
		X11Ref = NSUnionRect(X11Ref, [screen frame]);
	}
	// translate
	COCOA_TO_SCREEN_COORDINATES(X11Ref);
	FMTDevLog(@"X11 reference rect: %@", RECT_STR(X11Ref));

	bool activeWindowX11 = NO;
#endif // X11
	
	// window reference - windowing system agnostic
	void *window = NULL;
	
	// coordinates vars
	int x,y;
	unsigned int width, height;

	// error handling vars
	int errorCode = 0;
	
	// first try to get the window using accessibility API
	errorCode = AXUIGetActiveWindowGeometry(&window, &x, &y, &width, &height);
	
	if (errorCode != 0) {
#ifdef X11
		// try X11
		int errorCodeX11 = X11GetActiveWindowGeometry(&window, &x, &y, &width, &height);		
		if (errorCodeX11 != 0) {
			NSString *message = FMTStr(@"%@\n%@",FMTStrc(AXUIGetErrorMessage(errorCode)),FMTStrc(X11GetErrorMessage(errorCodeX11)));

			*error = SICreateError(message, kUnableToGetActiveWindowErrorCode);
			return;
		} else {
			FMTDevLog(@"window rect (x11): [%d %d] [%d %d]", x, y, width, height);
			
			// convert from X11 coordinates to Quartz CG coodinates
			x += X11Ref.origin.x;
			y += X11Ref.origin.y;
						
			activeWindowX11 = YES;
		}
#else
		*error = SICreateError(FMTStrc(AXUIGetErrorMessage(errorCode)), kUnableToGetActiveWindowErrorCode);
		return;
#endif // X11
	}
	
	// the window rect in screen coordinates
	NSRect windowRect = {
		{x, y},
		{width, height}
	};
	FMTDevLog(@"window rect: %@", RECT_STR(windowRect));
	
	// get the screen which is the best fit for the window
	NSScreen *screen = [self chooseScreenForWindow_:windowRect];
	
	// screen coordinates of the best fit window
	NSRect screenRect = [screen frame];
	FMTDevLog(@"screen rect (cocoa): %@", RECT_STR(screenRect));	
	COCOA_TO_SCREEN_COORDINATES(screenRect);
	FMTDevLog(@"screen rect: %@", RECT_STR(screenRect));	

	// visible screen coordinates of the best fit window
	NSRect visibleScreenRect = [screen visibleFrame];
	FMTDevLog(@"visible screen rect (cocoa): %@", RECT_STR(visibleScreenRect));	
	COCOA_TO_SCREEN_COORDINATES(visibleScreenRect);
	FMTDevLog(@"visible screen rect: %@", RECT_STR(visibleScreenRect));	
	
	// adjust the visibility
	// - menu bar
	// - dock
	screenRect.size.width += screenRect.origin.x - visibleScreenRect.origin.x;
	screenRect.size.height += screenRect.origin.y - visibleScreenRect.origin.y;

	// we need to translate from cocoa coordinates
	FMTDevLog(@"screen rect translated: %@", RECT_STR(screenRect));	
		
	// execute the actual action 
	ShiftItFunctionRef actionFunction = [action action];
	NSRect shiftedRect = actionFunction(screenRect.size, windowRect);
	FMTDevLog(@"shifted rect: %@", RECT_STR(shiftedRect));
	
	// translate geometry
	shiftedRect.origin.x += screenRect.origin.x;
	shiftedRect.origin.y += screenRect.origin.y;
	
#ifdef X11
	if (activeWindowX11) {
		// translate into X11 coordinates
		shiftedRect.origin.x -= X11Ref.origin.x;
		shiftedRect.origin.y -= X11Ref.origin.y;

		// adjust menu bar
		if ([screen hasMenuBar]) {
			shiftedRect.size.height -= GetMBarHeight();
		}
	} else {
		// adjust menu bar
		if ([screen hasMenuBar]) {
			shiftedRect.origin.y += GetMBarHeight();
		}
	}
#else
	// adjust menu bar
	if ([screen hasMenuBar]) {
		shiftedRect.origin.y += GetMBarHeight();
	}	
#endif // X11
		
	FMTDevLog(@"translated shifted rect: %@", RECT_STR(shiftedRect));
	
	x = (int) shiftedRect.origin.x;
	y = (int) shiftedRect.origin.y;
	width = (unsigned int) shiftedRect.size.width;
	height = (unsigned int) shiftedRect.size.height;
		
	// adjust window geometry
#ifdef X11
	if (activeWindowX11) {
		errorCode = X11SetWindowGeometry(window, x, y, width, height);
		if (errorCode != 0) {
			*error = SICreateError(FMTStrc(X11GetErrorMessage(errorCode)), kUnableToChangeWindowSizeOrPositionErrorCode);
		}
	} else {
		errorCode = AXUISetWindowGeometry(window, x, y, width, height);
		if (errorCode != 0) {
			*error = SICreateError(FMTStrc(AXUIGetErrorMessage(errorCode)), kUnableToChangeWindowSizeOrPositionErrorCode);
		}
	}
#else
	errorCode = AXUISetWindowGeometry(window, x, y, width, height);
	if (errorCode != 0) {
		*error = SICreateError(FMTStrc(AXUIGetErrorMessage(errorCode)), kUnableToChangeWindowSizeOrPositionErrorCode);		
	}
#endif
	
#ifdef X11
	if (activeWindowX11) {
		X11FreeWindowRef(window);
	} else {
		AXUIFreeWindowRef(window);
	}
#else
	AXUIFreeWindowRef(window);
#endif
}

- (NSScreen *)chooseScreenForWindow_:(NSRect)windowRect {
	// TODO: rename intgersect
	// TODO: all should be ***Rect
	
	NSScreen *fitScreen = [NSScreen mainScreen];
	float maxSize = 0;
	
	for (NSScreen *screen in [NSScreen screens]) {
		NSRect screenRect = [screen frame];
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