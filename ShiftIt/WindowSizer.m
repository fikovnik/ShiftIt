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

// reference to the carbon GetMBarHeight() function
extern short GetMBarHeight(void);

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

#define COCOA_TO_SCREEN_COORDINATES(rect) (rect).origin.y = [[NSScreen primaryScreen] frame].size.height - (rect).size.height - (rect).origin.y

@interface WindowSizer (Private)

- (NSScreen *)chooseScreenForWindow_:(NSRect)windowRect;
- (NSScreen *)nextScreenForAction:(ShiftItAction*)action window:(NSRect)windowRect;

@end


@implementation WindowSizer

SINGLETON_BOILERPLATE(WindowSizer, sharedWindowSize);

@synthesize lastActionExecuted;

// TODO: remove
- (id)init {
	if (![super init]) {
		return nil;
	}
	
	return self;
}


/**
 * The method is the heart of the ShiftIt app. It takes an
 * ShiftItAction and applies it to the current window.
 *
 * In order to understand what exactly what is going on it is important
 * to understand how the graphic coordinates works in OSX. There are two
 * coordinates systems: screen (quartz core graphics) and cocoa. The
 * former one has and origin on the top left corner of the primary
 * screen (the one with a menu bar) and the coordinates grows in east
 * and south direction. The latter has origin in the bottom left corner
 * of the primary window and grows in east and north direction. The
 * overview of the cocoa coordinates is in [1]. X11 on the other 
 * hand have its coordinate system originating on the
 * top left corner of the most top left window [2]. 
 *
 * In this method all coordinates are translated to be the screen
 * coordinates.
 * 
 * [1] http://bit.ly/aSmfae (apple official docs)
 * 
 * [2] http://www.linuxjournal.com/article/4879
 */
 - (void) shiftFocusedWindowUsing:(ShiftItAction *)action error:(NSError **)error {
	FMTAssertNotNil(action);
	
#ifdef X11
	 bool activeWindowX11 = NO;
	 NSRect X11Ref;
#endif // X11
	
	// window reference - windowing system agnostic
	void *window = NULL;
	
	// coordinates vars
	int x = 0, y = 0;
	unsigned int width = 0, height = 0;

	// error handling vars
	int errorCode = 0;
	
	// active window geometry
	
	// first try to get the window using accessibility API
	errorCode = AXUIGetActiveWindow(&window);
	
	if (errorCode != 0) {
#ifdef X11
		window = NULL;
		// try X11
		int errorCodeX11 = X11GetActiveWindow(&window);		
		if (errorCodeX11 != 0) {
			NSString *message = FMTStr(@"%@, %@",FMTStrc(AXUIGetErrorMessage(errorCode)),FMTStrc(X11GetErrorMessage(errorCodeX11)));

			*error = SICreateError(message, kUnableToGetActiveWindowErrorCode);
			return;
		}
		
		int errorCode = X11GetWindowGeometry(window, &x, &y, &width, &height);
		if (errorCode != 0) {
			*error = SICreateError(FMTStrc(X11GetErrorMessage(errorCode)), kUnableToGetWindowGeometryErrorCode);
			return;			
		}
		FMTDevLog(@"window rect (x11): [%d %d] [%d %d]", x, y, width, height);
				
		// following will make the X11 reference coordinate system
		// X11 coordinates starts at the very top left corner of the most top left window
		// basically it is a union of all screens with the beginning at the top left
		X11Ref = [[NSScreen primaryScreen] frame];
		for (NSScreen *screen in [NSScreen screens]) {
			X11Ref = NSUnionRect(X11Ref, [screen frame]);
		}
		// translate
		COCOA_TO_SCREEN_COORDINATES(X11Ref);
		FMTDevLog(@"X11 reference rect: %@", RECT_STR(X11Ref));

		// convert from X11 coordinates to Quartz CG coodinates
		x += X11Ref.origin.x;
		y += X11Ref.origin.y;
		
		activeWindowX11 = YES;		
#else
		*error = SICreateError(FMTStrc(AXUIGetErrorMessage(errorCode)), kUnableToGetActiveWindowErrorCode);
		return;
#endif // X11
	} else {
		int errorCode = AXUIGetWindowGeometry(window, &x, &y, &width, &height);
		
		if (errorCode != 0) {
			*error = SICreateError(FMTStrc(AXUIGetErrorMessage(errorCode)), kUnableToGetWindowGeometryErrorCode);
			return;
		}
	}
	
	// the window rect in screen coordinates
	NSRect windowRect = {
		{x, y},
		{width, height}
	};
	FMTDevLog(@"window rect: %@", RECT_STR(windowRect));
	
#ifndef NDEBUG
	 // dump screen info
	 for (NSScreen *screen in [NSScreen screens]) {
		 NSRect frame = [screen frame];
		 NSRect visibleFrame = [screen visibleFrame];
		 
		 COCOA_TO_SCREEN_COORDINATES(frame);
		 COCOA_TO_SCREEN_COORDINATES(visibleFrame);
		 FMTDevLog(@"Screen info: %@ frame: %@ visible frame: %@",screen, RECT_STR(frame), RECT_STR(visibleFrame));
	 }
#endif		 
	 
	// get the screen which is the best fit for the window
	 // check to see if the user has repeated a left or right shift
	 //    if so, move window to the screen next current one
	 NSScreen *screen; 
	screen = [self chooseScreenForWindow_:windowRect];
	
	// screen coordinates of the best fit window
	NSRect screenRect = [screen frame];
	FMTDevLog(@"screen rect (cocoa): %@", RECT_STR(screenRect));	
	COCOA_TO_SCREEN_COORDINATES(screenRect);
	FMTDevLog(@"screen rect: %@", RECT_STR(screenRect));	

	// visible screen coordinates of the best fit window
	// the visible screen denotes some inner rect of the screen rect which is visible - not occupied by menu bar or dock
	NSRect visibleScreenRect = [screen visibleFrame];
	FMTDevLog(@"visible screen rect (cocoa): %@", RECT_STR(visibleScreenRect));	
	COCOA_TO_SCREEN_COORDINATES(visibleScreenRect);
	FMTDevLog(@"visible screen rect: %@", RECT_STR(visibleScreenRect));	

	// execute shift it action to reposition the application window
	ShiftItFunctionRef actionFunction = [action action];
	NSRect shiftedRect = actionFunction(visibleScreenRect.size, windowRect);
	FMTDevLog(@"shifted window rect: %@", RECT_STR(shiftedRect));
	 
	 
	// readjust adjust the visibility
	// the shiftedRect is the new application window geometry relative to the screen originating at [0,0]
	// we need to shift it accordingly that is to the origin of the best fit screen (screenRect) and
	// take into account the visible area of such a screen - menu, dock, etc. which is in the visibleScreenRect
	shiftedRect.origin.x += screenRect.origin.x + visibleScreenRect.origin.x - screenRect.origin.x;
	shiftedRect.origin.y += screenRect.origin.y + visibleScreenRect.origin.y - screenRect.origin.y;
	 
	// we need to translate from cocoa coordinates
	FMTDevLog(@"shifted window within screen: %@", RECT_STR(shiftedRect));	
				
#ifdef X11
	if (activeWindowX11) {
		// translate into X11 coordinates
		shiftedRect.origin.x -= X11Ref.origin.x;
		shiftedRect.origin.y -= X11Ref.origin.y;
		
		// it seems that the X11 server 2.3.5 on snow leopard 10.6.4 on mac book pro
		// changes the origin of the coordinates depending on the relative 
		// positions of the screens next to each other if there is a screen
		// that is below the primary screen, than the X11 coordnates starts at
		// [0,m] of the screen coordinates (quartz) where m is the height of the
		// menu bar (GetMBarHeight()) otherwise it starts at [0,0].
		BOOL screenBelowPrimary = NO;
		for (NSScreen *s in [NSScreen screens]) {
			NSRect r = [s frame];
			COCOA_TO_SCREEN_COORDINATES(r);
			if (r.origin.y > 0) {
				screenBelowPrimary = YES;
				break;
			}
		}
		
		if (screenBelowPrimary || [screen isPrimary]) {
			shiftedRect.origin.y -= GetMBarHeight();
		}
	} 
#endif // X11
		
	FMTDevLog(@"translated shifted rect: %@", RECT_STR(shiftedRect));
	
	x = (int) shiftedRect.origin.x;
	y = (int) shiftedRect.origin.y;
	width = (unsigned int) shiftedRect.size.width;
	height = (unsigned int) shiftedRect.size.height;
		
	// adjust window geometry
	// there are apps that does not size continuously but rather discretely so
	// they have to be re-adjusted hence first set the size and then position
#ifdef X11
	if (activeWindowX11) {		
		FMTDevLog(@"adjusting position to %dx%d", x, y);
		errorCode = X11SetWindowPosition(window, x, y);
		if (errorCode != 0) {
			*error = SICreateError(FMTStrc(X11GetErrorMessage(errorCode)), kUnableToChangeWindowPositionErrorCode);
			return;
		}
		
		FMTDevLog(@"adjusting size to %dx%d", width, height);
		errorCode = X11SetWindowSize(window, width, height);
		if (errorCode != 0) {
			*error = SICreateError(FMTStrc(X11GetErrorMessage(errorCode)), kUnableToChangeWindowSizeErrorCode);
			return;
		}				
	} else {
#endif // X11
		FMTDevLog(@"adjusting position to %dx%d", x, y);
		errorCode = AXUISetWindowPosition(window, x, y);
		if (errorCode != 0) {
			*error = SICreateError(FMTStrc(AXUIGetErrorMessage(errorCode)), kUnableToChangeWindowPositionErrorCode);
			return;
		}
		
		FMTDevLog(@"adjusting size to %dx%d", width, height);
		errorCode = AXUISetWindowSize(window, width, height);
		if (errorCode != 0) {
			*error = SICreateError(FMTStrc(AXUIGetErrorMessage(errorCode)), kUnableToChangeWindowSizeErrorCode);
			return;
		}
#ifdef X11
	}
#endif // X11
		 
#ifdef X11
	if (activeWindowX11) {
		X11FreeWindowRef(window);
	} else {
		AXUIFreeWindowRef(window);
	}
#else
	AXUIFreeWindowRef(window);
#endif
	 
	 // this variable should only be stored if we're doing 1 of the 4 main shifts
	 if ([action identifier] == @"left" || [action identifier] == @"right" || [action identifier] == @"top" || [action identifier] == @"bottom")
		 lastActionExecuted = [action identifier];
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

- (NSScreen *)nextScreenForAction:(ShiftItAction*)action window:(NSRect)windowRect{
	// TODO: rename intgersect
	// TODO: all should be ***Rect
	
	//First find which screen the window is in
	float maxSize = 0;
	int currentScreenIndex = 0;
	for(int i = 0; i < [[NSScreen screens] count]; i++){
		NSRect screenRect = [[[NSScreen screens] objectAtIndex:i] frame];
		// need to convert coordinates
		COCOA_TO_SCREEN_COORDINATES(screenRect);
		
		NSRect intersectRect = NSIntersectionRect(screenRect, windowRect);
		
		if (intersectRect.size.width > 0 ) {
			float size = intersectRect.size.width * intersectRect.size.height;
			if (size > maxSize) {
				maxSize = size;
				currentScreenIndex = i;
			}
		}
	}
	
	NSScreen *currentScreen = [[NSScreen screens] objectAtIndex:currentScreenIndex]; 
	
	// Now find the adjascent screen	
	NSString *whichDirection = [action identifier];
	
	float leftClosestOffset = FLT_MAX; //arbitrarily large value
	float rightClosestOffset = FLT_MAX; //arbitrarily large value
	float leftFarthestOffset = 0;
	float rightFarthestOffset = 0;

	int leftClosestIndex = -1;
	int rightClosestIndex = -1;
	int leftFarthestIndex = -1;
	int rightFarthestIndex = -1;
	
	//this gives the screen in which the active window resides
	for(int i = 0; i < [[NSScreen screens] count]; i++){
		NSScreen *otherScreen = [[NSScreen screens] objectAtIndex:i];
		if (otherScreen == currentScreen) // if it's the same screen
			continue;
		
		float screenOffset = otherScreen.frame.origin.x - currentScreen.frame.origin.x;		
		
		//find the closest screens to left and right
		if (screenOffset < 0) { // screen is left of current
			if (fabs(screenOffset) < fabs(leftClosestOffset)) {
				leftClosestOffset = screenOffset;
				leftClosestIndex = i;
			}
			
			if (fabs(screenOffset) > fabs(leftFarthestOffset)) {
				leftFarthestOffset = screenOffset;
				leftFarthestIndex = i;
			}
		}
		else { //screen is right of current
			if (fabs(screenOffset) < fabs(rightClosestOffset)){
				rightClosestOffset = screenOffset;
				rightClosestIndex = i;
			}
			
			if (fabs(screenOffset) > fabs(rightFarthestOffset)) {
				rightFarthestOffset = screenOffset;
				rightFarthestIndex = i;
			}
		}

	}
	
	int target = 0;
	if (whichDirection == @"left") 
		(leftClosestIndex == -1) ? (target = rightFarthestIndex) : (target = leftClosestIndex);
	else if (whichDirection == @"right")
		(rightClosestIndex == -1) ? (target = leftFarthestIndex) : (target = rightClosestIndex);
	else //action must be left or right-- if not, bail
		return [NSScreen mainScreen]; // return the current screen
	
	return [[NSScreen screens] objectAtIndex:target];
}

@end