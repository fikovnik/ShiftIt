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
#import "AXWindowManager.h"
#import "FMTDefines.h"

#define POINT_STR(point) FMTStr(@"[%f %f]", (point).x, (point).y)
#define SIZE_STR(size) FMTStr(@"[%f %f]", (size).width, (size).height)
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
    
    windowManager_ = [[AXWindowManager sharedAXWindowManager] retain];
    
	return self;
}

- (void) dealloc {	
    [windowManager_ release];
	[super dealloc];
}

- (BOOL) isCurrentWindowInFullScreen {
    AXUIElementRef window = NULL;
    NSError *error = nil;
    
    if (![windowManager_ getFocusedWindow:&window error:&error]) {
        FMTDevLog(@"Unable to get active window reference");
		return NO;
    }
    
    BOOL fullScreenMode;
    if (![windowManager_ getFullScreenMode:&fullScreenMode window:window error:&error]) {
        FMTDevLog(@"Unable to check window reference");
		return NO;
    }
    
    return fullScreenMode;
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
- (BOOL) shiftFocusedWindowUsing:(ShiftItAction *)action error:(NSError **)error {
	FMTAssertNotNil(action);
    
	// window reference - windowing system agnostic
	AXUIElementRef window = nil;
    
	
    NSRect windowRectWithoutDrawers = NSMakeRect(0, 0, 0, 0); // window rect
	NSRect drawersRect = NSMakeRect(0, 0, 0, 0); // drawers of the window
    NSRect windowRect = NSMakeRect(0, 0, 0, 0); // window with drawers
	
	BOOL useDrawers = [[NSUserDefaults standardUserDefaults] boolForKey:kIncludeDrawersPrefKey];
	int numberOfTries = [[NSUserDefaults standardUserDefaults] integerForKey:kNumberOfTriesPrefKey];
    if (numberOfTries < 0 || numberOfTries > kMaxNumberOfTries) {
        numberOfTries = 1;
    }
    
    NSError *cause = nil;
    
	// first try to get the window using accessibility API
	if (![windowManager_ getFocusedWindow:&window error:&cause]) {
		*error = SICreateErrorWithCause(@"Unable to get active window", kUnableToGetActiveWindowErrorCode, cause);
		return NO;
	} 
    
    if (![windowManager_ getGeometry:&windowRectWithoutDrawers window:window error:&cause]) {
        *error = SICreateErrorWithCause(@"Unable to get window geometry", kUnableToGetWindowGeometryErrorCode, cause);
        return NO;
    }
    
    if (![windowManager_ isWindowMoveable:window]) {
        FMTDevLog(@"Window is not moveable");
        return YES;
    }

    if (![windowManager_ isWindowResizeable:window]) {
        FMTDevLog(@"Window is not resizeable");
        return YES;
    }

    FMTDevLog(@"Window geometry without drawers: %@", RECT_STR(windowRectWithoutDrawers));
    
    // drawers
    if (useDrawers) {
        if (![windowManager_ getDrawersGeometry:&drawersRect window:window error:&cause]) {
            FMTDevLog(@"Unable to get window drawers: %@", [cause description]);
        } else if (drawersRect.size.width > 0) {
            // there are some drawers
            FMTDevLog(@"Drawers geometry: %@", RECT_STR(drawersRect));
            
            windowRect = NSUnionRect(windowRect, drawersRect);
            FMTDevLog(@"Window geometry with drawers: %@", RECT_STR(windowRect));
        } else {
            windowRect = windowRectWithoutDrawers;                
        }
    } else {
        windowRect = windowRectWithoutDrawers;
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
	FMTDevLog(@"Screen geometry: %@", RECT_STR(screenRect));	
	
	// visible screen coordinates of the best fit window
	// the visible screen denotes some inner rect of the screen rect which is visible - not occupied by menu bar or dock
	NSRect visibleScreenRect = [screen visibleFrame];
	//	FMTDevLog(@"visible screen rect (cocoa): %@", RECT_STR(visibleScreenRect));	
	COCOA_TO_SCREEN_COORDINATES(visibleScreenRect);
	FMTDevLog(@"Visible screen geometry: %@", RECT_STR(visibleScreenRect));	
	
	// readjust adjust the window rect to be relative of the screen at origin [0,0]
	NSRect relWindowRect = windowRect;
	relWindowRect.origin.x -= visibleScreenRect.origin.x;
	relWindowRect.origin.y -= visibleScreenRect.origin.y;
	FMTDevLog(@"Window geometry relative to [0,0]: %@", RECT_STR(relWindowRect));	
	
	// execute shift it action to reposition the application window
	ShiftItFunctionRef actionFunction = [action action];
	NSRect shiftedRect = actionFunction(visibleScreenRect.size, relWindowRect);
	FMTDevLog(@"Shifted window geometry: %@", RECT_STR(shiftedRect));
	
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
		
		FMTDevLog(@"Shifted window geometry after drawers adjustements: %@", RECT_STR(shiftedRect));
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
		// move window
		FMTDevLog(@"moving window to: %@", POINT_STR(shiftedRect.origin));		
		if (![windowManager_ setPosition:shiftedRect.origin window:window error:&cause] != 0) {
			*error = SICreateErrorWithCause(@"Unable to move window", kUnableToChangeWindowPositionErrorCode, cause);
			return NO;
		}
		
        // here we will keep the size after the second attempt
        NSRect windowRect2;
        // TODO: it woudl be actually much better to see if we are converging rather than blindly execute n steps
        {
            for (int i=1; i<=numberOfTries; i++) {
                // resize window
                FMTDevLog(@"resizing to: %@ (%d. attempt)", SIZE_STR(shiftedRect.size), i);
                if (![windowManager_ setSize:shiftedRect.size window:window error:&cause] != 0) {
                    *error = SICreateErrorWithCause(@"Unable to resize window", kUnableToChangeWindowSizeErrorCode, cause);
                    return NO;
                }
                
                // check how was it resized
                NSRect windowRect3;
                if (![windowManager_ getGeometry:&windowRect3 window:window error:&cause]) {
                    *error = SICreateErrorWithCause(@"Unable to get window geometry", kUnableToGetWindowGeometryErrorCode, cause);
                    return NO;
                }
                FMTDevLog(@"window resized to: %@ (%d. attempt)", SIZE_STR(windowRect3.size), i);
                
                if (NSEqualSizes(windowRect3.size, shiftedRect.size)) {
                    break;
                } else if (i > 1 && (NSEqualSizes(windowRect3.size, windowRect2.size))) {
                    // it seems that more attempts wont change anything
                    FMTDevLog(@"The %d attempt is the same as %d so no effect (likely a discretely sizing window)", i, i-1);
                    break;
                }
                windowRect2 = windowRect3;
            }
        }
        
		// there are apps that does not size continuously but rather discretely so
		// they have to be re-adjusted
		int dx = 0;
		int dy = 0;
		
		// in order to check for the bottom anchor we have to deal with the menu bar again
		int mbarAdj = GetMBarHeight();
        
		// get the anchor and readjust the size
		if (shiftedRect.origin.x + shiftedRect.size.width == visibleScreenRect.size.width || shiftedRect.origin.y + shiftedRect.size.height == visibleScreenRect.size.height + mbarAdj) {
            NSRect windowRect2;
            if (![windowManager_ getGeometry:&windowRect2 window:window error:&cause]) {
                *error = SICreateErrorWithCause(@"Unable to get window geometry", kUnableToGetWindowGeometryErrorCode, cause);
                return NO;
            }
            
			FMTDevLog(@"window resized to: %@", SIZE_STR(windowRect2.size));
			
			// check whether the anchor is at the right part of the screen
			if (shiftedRect.origin.x + shiftedRect.size.width == visibleScreenRect.size.width
				&& shiftedRect.origin.x > visibleScreenRect.size.width - shiftedRect.size.width - shiftedRect.origin.x) {
				dx = shiftedRect.size.width - windowRect2.size.width;
			}
			
			// check whether the anchor is at the bottom part of the screen
			if (shiftedRect.origin.y + shiftedRect.size.height == visibleScreenRect.size.height + mbarAdj
				&& shiftedRect.origin.y - mbarAdj > visibleScreenRect.size.height + mbarAdj - shiftedRect.size.height - shiftedRect.origin.y) {
				dy = shiftedRect.size.height - windowRect2.size.height;
			}
			
			if (dx != 0 || dy != 0) {
				// there have to be two separate move actions. cocoa window could not be resize over the screen boundaries
				FMTDevLog(@"adjusting by delta: %dx%d", dx, dy);
                NSPoint dp = NSMakePoint(shiftedRect.origin.x+dx, shiftedRect.origin.y+dy);        
				if (![windowManager_ setPosition:dp window:window error:&cause]) {
					*error = SICreateErrorWithCause(@"Unable to move window", kUnableToChangeWindowPositionErrorCode, cause);
					return NO;
				}		
			}
		}
        
        // TODO: make sure window is always visible
        
	} else {
		FMTDevLog(@"Shifted window origin and dimensions are the same");
	}
	
    [windowManager_ freeWindow:window];
    return YES;
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