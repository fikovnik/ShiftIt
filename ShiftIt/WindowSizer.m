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

#define RECT_STR(rect) FMTStr(@"[%f %f] [%f %f]", (rect).origin.x, (rect).origin.y, (rect).size.width, (rect).size.height)
#define COCOA_TO_SCREEN_COORDINATES(rect) (rect).origin.y = [[NSScreen primaryScreen] frame].size.height - (rect).size.height - (rect).origin.y

const int kMaxNumberOfTries = 20;

// reference to the carbon GetMBarHeight() function
extern short GetMBarHeight(void);

@interface NSScreen (Private)

+ (NSScreen *)primaryScreen;
- (BOOL)isPrimary;
- (BOOL)isBelowPrimary;

@end

@implementation NSScreen (Private)

+ (NSScreen *)primaryScreen {
	return [[NSScreen screens] objectAtIndex:0];
}

- (BOOL)isPrimary {
	return self == [NSScreen primaryScreen];
}

- (BOOL)isBelowPrimary { 			
	BOOL isBellow = NO;
	for (NSScreen *s in [NSScreen screens]) {
		NSRect r = [s frame];
		COCOA_TO_SCREEN_COORDINATES(r);
		if (r.origin.y > 0) {
			isBellow = YES;
			break;
		}
	}
	return isBellow;
}

@end


@interface WindowSizer (Private)

- (NSScreen *)chooseScreenForWindow_:(NSRect)windowRect;
- (NSScreen *)nextScreenForAction_:(ShiftItAction*)action window:(NSRect)windowRect;

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

- (void) dealloc {	
	[super dealloc];
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
// TODO: get rid of the c like functions from AXUIUtils
- (void) shiftFocusedWindowUsing:(ShiftItAction *)action error:(NSError **)error {
	FMTAssertNotNil(action);
		
	// window reference - windowing system agnostic
	void *window = NULL;
	
	// coordinates vars
	int x = 0, y = 0;
	unsigned int width = 0, height = 0;
	
	// drawers of the window
	NSRect drawersRect = {{0,0},{0,0}};
	
	BOOL useDrawers = [[NSUserDefaults standardUserDefaults] boolForKey:kIncludeDrawersPrefKey];
	int numberOfTries = [[NSUserDefaults standardUserDefaults] integerForKey:kNumberOfTriesPrefKey];
    if (numberOfTries < 0 || numberOfTries > kMaxNumberOfTries) {
        numberOfTries = 1;
    }
	
	// window rect
	NSRect windowRect;
    NSRect windowRectWithoutDrawers;
	
	// error handling vars
	int errorCode = 0;
	
	// active window geometry
	
	// first try to get the window using accessibility API
	errorCode = AXUIGetActiveWindow(&window);
	
	if (errorCode != 0) {
		*error = SICreateError(FMTStrc(AXUIGetErrorMessage(errorCode)), kUnableToGetActiveWindowErrorCode);
		return;
	} else {
		int errorCode = AXUIGetWindowGeometry(window, &x, &y, &width, &height);
		
		if (errorCode != 0) {
			*error = SICreateError(FMTStrc(AXUIGetErrorMessage(errorCode)), kUnableToGetWindowGeometryErrorCode);
			return;
		}
		
		windowRect.origin.x = x;
		windowRect.origin.y = y;
		windowRect.size.width = width;
		windowRect.size.height = height;
        FMTDevLog(@"Window rect: %@", RECT_STR(windowRect));
		
		// drawers
		if (useDrawers) {
			errorCode = AXUIGetWindowDrawersUnionRect(window, &drawersRect);
			
			if (errorCode != 0) {
				FMTDevLog(@"Unable to get window drawers: %d", errorCode);
			} else {
				FMTDevLog(@"Drawers rect: %@", RECT_STR(drawersRect));
			}
			
			if (drawersRect.size.width > 0) {
                windowRectWithoutDrawers = windowRect;
				windowRect = NSUnionRect(windowRect, drawersRect);
                FMTDevLog(@"Window rect with drawers: %@", RECT_STR(windowRect));
			}
		}
	}
				
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
	// if so, move window to the screen next current one
	NSScreen *screen = [self chooseScreenForWindow_:windowRect];
		
	// screen coordinates of the best fit window
	NSRect screenRect = [screen frame];
	//	FMTDevLog(@"screen rect (cocoa): %@", RECT_STR(screenRect));	
	COCOA_TO_SCREEN_COORDINATES(screenRect);
	FMTDevLog(@"screen rect: %@", RECT_STR(screenRect));	
	
	// visible screen coordinates of the best fit window
	// the visible screen denotes some inner rect of the screen rect which is visible - not occupied by menu bar or dock
	NSRect visibleScreenRect = [screen visibleFrame];
	//	FMTDevLog(@"visible screen rect (cocoa): %@", RECT_STR(visibleScreenRect));	
	COCOA_TO_SCREEN_COORDINATES(visibleScreenRect);
	FMTDevLog(@"visible screen rect: %@", RECT_STR(visibleScreenRect));	
	
	// readjust adjust the window rect to be relative of the screen at origin [0,0]
	NSRect relWindowRect = windowRect;
	relWindowRect.origin.x -= visibleScreenRect.origin.x;
	relWindowRect.origin.y -= visibleScreenRect.origin.y;
	FMTDevLog(@"window rect relative to [0,0]: %@", RECT_STR(relWindowRect));	
	
	// execute shift it action to reposition the application window
	ShiftItFunctionRef actionFunction = [action action];
	NSRect shiftedRect = actionFunction(visibleScreenRect.size, relWindowRect);
	FMTDevLog(@"shifted window rect: %@", RECT_STR(shiftedRect));
	
	// drawers
	if (useDrawers && drawersRect.size.width > 0) {
        int dx = windowRectWithoutDrawers.origin.x - windowRect.origin.x;
        int dy = windowRect.origin.y - windowRectWithoutDrawers.origin.y;
        int dw = windowRect.size.width - windowRectWithoutDrawers.size.width;
        int dh = windowRect.size.height - windowRectWithoutDrawers.size.height;
        
		shiftedRect.origin.x += dx;
		shiftedRect.origin.y -= dy;
		shiftedRect.size.width -= dw;
		shiftedRect.size.height -= dh;
		
		FMTDevLog(@"shifted window rect after drawers adjustements: %@", RECT_STR(shiftedRect));
	}
	
	// readjust adjust the visibility
	// the shiftedRect is the new application window geometry relative to the screen originating at [0,0]
	// we need to shift it accordingly that is to the origin of the best fit screen (screenRect) and
	// take into account the visible area of such a screen - menu, dock, etc. which is in the visibleScreenRect
	shiftedRect.origin.x += screenRect.origin.x + visibleScreenRect.origin.x - screenRect.origin.x;
	shiftedRect.origin.y += screenRect.origin.y + visibleScreenRect.origin.y - screenRect.origin.y;// - ([screen isPrimary] ? GetMBarHeight() : 0);
	
	// we need to translate from cocoa coordinates
	FMTDevLog(@"shifted window within screen: %@", RECT_STR(shiftedRect));	
	
	if (!NSEqualRects(windowRect, shiftedRect)) {
				
		FMTDevLog(@"translated shifted rect: %@", RECT_STR(shiftedRect));
		
		x = (int) shiftedRect.origin.x;
		y = (int) shiftedRect.origin.y;
		width = (unsigned int) shiftedRect.size.width;
		height = (unsigned int) shiftedRect.size.height;
		
		// move window
		FMTDevLog(@"moving window to: %dx%d", x, y);		
		errorCode = AXUISetWindowPosition(window, x, y);
		if (errorCode != 0) {
			*error = SICreateError(FMTStrc(AXUIGetErrorMessage(errorCode)), kUnableToChangeWindowPositionErrorCode);
			return;
		}
		
        // here we will keep the size after the second attempt
        {
            unsigned int width2=0, height2=0; 
            for (int i=1; i<=numberOfTries; i++) {
                // resize window
                FMTDevLog(@"resizing to: %dx%d (%d. attempt)", width, height, i);
                errorCode = AXUISetWindowSize(window, width, height);
                if (errorCode != 0) {
                    *error = SICreateError(FMTStrc(AXUIGetErrorMessage(errorCode)), kUnableToChangeWindowSizeErrorCode);
                    return;
                }
                
                // check how was it resized
                int unused;
                unsigned int width3=0, height3=0; 
                errorCode = AXUIGetWindowGeometry(window, &unused, &unused, &width3, &height3);
                if (errorCode != 0) {
                    *error = SICreateError(FMTStrc(AXUIGetErrorMessage(errorCode)), kUnableToGetWindowGeometryErrorCode);
                    return;
                }
                FMTDevLog(@"window resized to: %dx%d (%d. attempt)", width3, height3, i);
                
                if (width == width3 && height == height3) {
                    break;
                } else if (i > 1 && (width3 == width2 && height3 == height2)) {
                        // it seems that more attempts wont change anything
                        FMTDevLog(@"The %d attempt is the same as %d so no effect (likely a discretely sizing window)", i, i-1);
                        break;
                }
                width2 = width3;
                height2 = height3;
            }
        }
        
		// there are apps that does not size continuously but rather discretely so
		// they have to be re-adjusted
		int dx = 0;
		int dy = 0;
		
		// in order to check for the bottom anchor we have to deal with the menu bar again
		int mbarAdj = GetMBarHeight();
	
		// get the anchor and readjust the size
		if (x + width == visibleScreenRect.size.width || y + height == visibleScreenRect.size.height + mbarAdj) {
			int unused;
			unsigned int width2,height2; 
			
			// check how was it resized
			errorCode = AXUIGetWindowGeometry(window, &unused, &unused, &width2, &height2);
			if (errorCode != 0) {
				*error = SICreateError(FMTStrc(AXUIGetErrorMessage(errorCode)), kUnableToGetWindowGeometryErrorCode);
				return;
			}
			FMTDevLog(@"window resized to: %dx%d", width2, height2);
			
			// check whether the anchor is at the right part of the screen
			if (x + width == visibleScreenRect.size.width
				&& x > visibleScreenRect.size.width - width - x) {
				dx = width - width2;
			}
			
			// check whether the anchor is at the bottom part of the screen
			if (y + height == visibleScreenRect.size.height + mbarAdj
				&& y - mbarAdj > visibleScreenRect.size.height + mbarAdj - height - y) {
				dy = height - height2;
			}
			
			if (dx != 0 || dy != 0) {
				// there have to be two separate move actions. cocoa window could not be resize over the screen boundaries
				FMTDevLog(@"adjusting by delta: %dx%d", dx, dy);		
				errorCode = AXUISetWindowPosition(window, x+dx, y+dy);
				if (errorCode != 0) {
					*error = SICreateError(FMTStrc(AXUIGetErrorMessage(errorCode)), kUnableToChangeWindowPositionErrorCode);
					return;
				}		
			}
		}
        
        // TODO: make sure window is always visible
        
	} else {
		FMTDevLog(@"Shifted window origin and dimensions are the same");
	}
	
	AXUIFreeWindowRef(window);	
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