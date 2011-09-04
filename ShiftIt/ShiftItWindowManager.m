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

#import "ShiftItWindowManager.h"
#import "ShiftIt.h"
#import "AbstractShiftItAction.h"
#import "AXWindowDriver.h"
#import "FMTDefines.h"

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

#pragma mark ShiftIt Window Manager private

@interface ShiftItWindowManager (Private)

+ (SIScreen *) chooseScreenForWindowGeometry_:(NSRect)geometry;

@end

#pragma mark SI Screen

@interface SIScreen ()

@property (readonly) NSRect screenRect_;
@property (readonly) NSRect visibleRect_;

@end

@implementation SIScreen

@dynamic size;
@synthesize primary = primary_;
@synthesize screenRect_;
@synthesize visibleRect_;

- (id) initWithNSScreen:(NSScreen *)screen {
	FMTAssertNotNil(screen);
    
	if (![super init]) {
		return nil;
	}
    
	// screen coordinates of the best fit window
	screenRect_ = [screen frame];
	COCOA_TO_SCREEN_COORDINATES(screenRect_);
    
	// visible screen coordinates of the best fit window
	// the visible screen denotes some inner rect of the screen frame
	// which is visible - not occupied by menu bar or dock
	visibleRect_ = [screen visibleFrame];
	COCOA_TO_SCREEN_COORDINATES(visibleRect_);
    
	primary_ = [screen isPrimary];
    
	return self;
}

+ (SIScreen *) screenFromNSScreen:(NSScreen *)screen {
    return [[[SIScreen alloc] initWithNSScreen:screen] autorelease];
}


- (NSSize) size {
	return visibleRect_.size;
}

@end

#pragma mark SIWindow

@interface SIWindow ()

@property (readonly) NSRect drawersRect_;
@property (readonly) NSRect windowRect_;
@property (readonly) SIWindowRef ref_;
@property (readonly) BOOL hasDrawers_;


- (id) initWithRef:(SIWindowRef)ref 
        windowRect:(NSRect)windowRect 
       drawersRect:(NSRect)drawersRect 
            screen:(SIScreen *)screen;

@end

@implementation SIWindow

@dynamic origin;
@dynamic size;
@dynamic hasDrawers_;
@synthesize geometry = geometry_;
@synthesize screen = screen_;
@synthesize drawersRect_;
@synthesize windowRect_;
@synthesize ref_;

- (id) initWithRef:(SIWindowRef)ref 
        windowRect:(NSRect)windowRect 
       drawersRect:(NSRect)drawersRect 
            screen:(SIScreen *)screen {
    
	// TODO: check for invalid wids
	FMTAssertNotNil(ref);
	FMTAssertNotNil(screen);
    
	if (![super init]) {
		return nil;
	}
    
	ref_ = ref;
	windowRect_ = windowRect;
    drawersRect_ = drawersRect;
    
    if (drawersRect_.size.width > 0) {
        geometry_ = NSUnionRect(windowRect_, drawersRect_);            
    } else {
        geometry_ = windowRect_;                
    }    

	screen_ = [screen retain];
    
	return self;
}

- (void) dealloc {
	[screen_ release];
    
	[super dealloc];
}

#pragma mark SIWindow dynamic properties

- (BOOL) hasDrawers_ {
    return drawersRect_.size.width > 0;
}

- (NSPoint) origin {
	return geometry_.origin;
}

- (NSSize) size {
	return geometry_.size;
}

@end

#pragma mark Default Window Context

@interface DefaultWindowContext : NSObject<WindowContext> {
 @private
    id<WindowDriver> driver_;
    BOOL useDrawers_;
    int numberOfTries_;
    int menuBarHeight_;

    NSMutableArray *windows_;
}

- (id) initWithDriver:(id<WindowDriver>)driver;

@end

@implementation DefaultWindowContext

- (id) initWithDriver:(id<WindowDriver>)driver {
    FMTAssertNotNil(driver);
    
    if (![self init]) {
        return nil;
    }
    
    driver_ = [driver retain];
    windows_ = [[NSMutableArray alloc] init];
    menuBarHeight_ = GetMBarHeight();

    useDrawers_ = [[NSUserDefaults standardUserDefaults] boolForKey:kIncludeDrawersPrefKey];

    numberOfTries_ = [[NSUserDefaults standardUserDefaults] integerForKey:kNumberOfTriesPrefKey];
    if (numberOfTries_ < 0 || numberOfTries_ > kMaxNumberOfTries) {
        numberOfTries_ = 1;
    }

#ifndef NDEBUG
	// dump screen info
	for (NSScreen *screen in [NSScreen screens]) {
		NSRect frame = [screen frame];
		NSRect visibleFrame = [screen visibleFrame];
		
		COCOA_TO_SCREEN_COORDINATES(frame);
		COCOA_TO_SCREEN_COORDINATES(visibleFrame);
		FMTLogDebug(@"Screen info: %@ frame: %@ visible frame: %@",screen, RECT_STR(frame), RECT_STR(visibleFrame));
	}
#endif

    return self;
}

- (void) dealloc {
    for (SIWindow *window in windows_) {
        [driver_ freeWindow:[window ref_]];
    }
    
    [windows_ release];
    [driver_ release];
    
    [super dealloc];
}

- (BOOL) getFocusedWindow:(SIWindow **)window error:(NSError **)error {
    SIWindowRef windowRef = nil;
    
    if (![driver_ getFocusedWindow:&windowRef error:error]) {
        return NO;
    }
    
    
    NSRect windowRect = NSMakeRect(0, 0, 0, 0); // window rect
	NSRect drawersRect = NSMakeRect(0, 0, 0, 0); // drawers of the window
    NSRect geometry;
    
    if (![driver_ getWindow:windowRef geometry:&windowRect error:error]) {
        return NO;
    }
    
    FMTLogDebug(@"Window geometry without drawers: %@", RECT_STR(windowRect));
    
    if (useDrawers_) {
        NSError *cause = nil;
        
        if (![driver_ getWindow:window drawersGeometry:&drawersRect error:&cause]) {
            FMTLogInfo(@"Unable to get window drawers: %@", [cause description]);
            geometry = windowRect;
        } else if (drawersRect.size.width > 0) {
            // there are some drawers            
            FMTLogDebug(@"Drawers geometry: %@", RECT_STR(drawersRect));            
            geometry = NSUnionRect(windowRect, drawersRect);
            FMTLogDebug(@"Window geometry with drawers: %@", RECT_STR(geometry));
        } else {
            geometry = windowRect;
        }
    }
    
//    BOOL flag;
//    
//    // check if it is moveable
//    if (![driver_ canWindow:window move:&flag error:&cause]) {
//        *error = SICreateErrorWithCause(@"Unable to check if window is moveable", kWindowManagerFailureErrorCode, cause);
//        return NO;        
//    }
//    if (!flag) {
//        FMTLogInfo(@"Window is not moveable");
//        return YES;
//    }
//    
//    // check if it is moveable
//    if (![driver_ canWindow:window resize:&flag error:&cause]) {
//        *error = SICreateErrorWithCause(@"Unable to check if window is resizeable", kWindowManagerFailureErrorCode, cause);
//        return NO;        
//    }
//    if (!flag) {
//        FMTLogInfo(@"Window is not resizeable");
//        return YES;
//    }

    
    SIScreen *screen = [ShiftItWindowManager chooseScreenForWindowGeometry_:geometry];
    *window = [[SIWindow alloc] initWithRef:windowRef windowRect:windowRect drawersRect:drawersRect screen:screen];
    [windows_ addObject:[*window retain]];
    
    return YES;
}

// TODO: make sure that the geometry makes sense
- (BOOL) setWindow:(SIWindow *)window geometry:(NSRect)geometry error:(NSError **)error {
	FMTLogDebug(@"Setting window geometry: %@", RECT_STR(geometry));
	
    NSRect windowRect = [window windowRect_];
    NSRect windowRectWithDrawers = [window geometry];
    NSRect screenRect = [[window screen] screenRect_];
    NSRect visibleScreenRect = [[window screen] visibleRect_];
    
    // STEP 1: readjust the drawers
	// when moving the drawers are not taken into an account so need to manually
    // adjust the new position and size relative to the rect of drawers
    
	if (useDrawers_ && [window hasDrawers_]) {
        int dx = windowRect.origin.x - windowRectWithDrawers.origin.x;
        int dy = windowRectWithDrawers.origin.y - windowRect.origin.y;
        int dw = windowRectWithDrawers.size.width - windowRect.size.width;
        int dh = windowRectWithDrawers.size.height - windowRect.size.height;
        
		geometry.origin.x += dx;
		geometry.origin.y -= dy;
		geometry.size.width -= dw;
		geometry.size.height -= dh;
		
		FMTLogDebug(@"Setting window geometry after drawers adjustements: %@", RECT_STR(geometry));
	}
	
	// STEP 2: readjust adjust the visibility
	// the geometry is the new application window geometry relative to the screen originating at [0,0]
	// we need to shift it accordingly that is to the origin of the best fit screen (screenRect) and
	// take into account the visible area of such a screen - menu, dock, etc. which is in the visibleScreenRect
    // ************* FIXME !!!!!
	geometry.origin.x += screenRect.origin.x + visibleScreenRect.origin.x - screenRect.origin.x;
	geometry.origin.y += screenRect.origin.y + visibleScreenRect.origin.y - screenRect.origin.y;// - ([screen isPrimary] ? GetMBarHeight() : 0);
	
	// we need to translate from cocoa coordinates
	FMTLogDebug(@"Setting window geometry after readjusting the visiblity: %@", RECT_STR(geometry));	
	
    NSError *cause = nil;
	if (!NSEqualRects(windowRectWithDrawers, geometry)) {				
		// move window
		FMTLogDebug(@"Moving window to: %@", POINT_STR(geometry.origin));		
		if (![driver_ setWindow:[window ref_] position:geometry.origin error:&cause] != 0) {
			*error = SICreateErrorWithCause(@"Unable to move window", kWindowManagerFailureErrorCode, cause);
			return NO;
		}
		
        // here we will keep the size after the second attempt
        NSRect windowRect2;
        // TODO: it woudl be actually much better to see if we are converging rather than blindly execute n steps
        {
            for (int i=1; i<=numberOfTries_; i++) {
                // resize window
                FMTLogDebug(@"Resizing to: %@ (%d. attempt)", SIZE_STR(geometry.size), i);
                if (![driver_ setWindow:[window ref_] size:geometry.size error:&cause] != 0) {
                    *error = SICreateErrorWithCause(@"Unable to resize window", kWindowManagerFailureErrorCode, cause);
                    return NO;
                }
                
                // check how was it resized
                NSRect windowRect3;
                if (![driver_ getWindow:[window ref_] geometry:&windowRect3 error:&cause]) {
                    *error = SICreateErrorWithCause(@"Unable to get window geometry", kWindowManagerFailureErrorCode, cause);
                    return NO;
                }
                FMTLogDebug(@"Window resized to: %@ (%d. attempt)", SIZE_STR(windowRect3.size), i);
                
                if (NSEqualSizes(windowRect3.size, geometry.size)) {
                    break;
                } else if (i > 1 && (NSEqualSizes(windowRect3.size, windowRect2.size))) {
                    // it seems that more attempts wont change anything
                    FMTLogDebug(@"The %d attempt is the same as %d so no effect (likely a discretely sizing window)", i, i-1);
                    break;
                }
                windowRect2 = windowRect3;
            }
        }
        
		// there are apps that does not size continuously but rather discretely so
		// they have to be re-adjusted
//		int dx = 0;
//		int dy = 0;
		
		// get the anchor and readjust the size
//		if (geometry.origin.x + geometry.size.width == visibleScreenRect.size.width 
//            || geometry.origin.y + geometry.size.height == visibleScreenRect.size.height + mbarAdj) {
//            NSRect windowRect2;
//            if (![driver_ getWindow:[window ref_] geometry:&windowRect2 error:&cause]) {
//                *error = SICreateErrorWithCause(@"Unable to get window geometry", kWindowManagerFailureErrorCode, cause);
//                return NO;
//            }
//            
//			FMTLogDebug(@"Window resized to: %@", SIZE_STR(windowRect2.size));
//			
//			// check whether the anchor is at the right part of the screen
//			if (geometry.origin.x + geometry.size.width == visibleScreenRect.size.width
//				&& geometry.origin.x > visibleScreenRect.size.width - geometry.size.width - geometry.origin.x) {
//				dx = geometry.size.width - windowRect2.size.width;
//			}
//			
//			// check whether the anchor is at the bottom part of the screen
//			if (geometry.origin.y + geometry.size.height == visibleScreenRect.size.height + mbarAdj
//				&& geometry.origin.y - mbarAdj > visibleScreenRect.size.height + mbarAdj - geometry.size.height - geometry.origin.y) {
//				dy = geometry.size.height - windowRect2.size.height;
//			}
//			
//			if (dx != 0 || dy != 0) {
//				// there have to be two separate move actions. cocoa window could not be resize over the screen boundaries
//				FMTLogDebug(@"Adjusting by delta: %dx%d", dx, dy);
//                NSPoint dp = NSMakePoint(geometry.origin.x+dx, geometry.origin.y+dy);        
//				if (![driver_ setWindow:window position:dp error:&cause]) {
//					*error = SICreateErrorWithCause(@"Unable to move window", kWindowManagerFailureErrorCode, cause);
//					return NO;
//				}		
//			}
//		}
        
        // TODO: make sure window is always visible
        
	} else {
		FMTLogInfo(@"Shifted window origin and dimensions are the same");
	}

    return YES;
}

- (BOOL) toggleZoomOnWindow:(SIWindow *)window error:(NSError **)error {
    FMTAssertNotNil(window);
    FMTAssertNotNil(error);
    
    return [driver_ toggleZoomOnWindow:[window ref_] error:error];
}

- (BOOL) toggleFullScreenOnWindow:(SIWindow *)window error:(NSError **)error {
    FMTAssertNotNil(window);
    FMTAssertNotNil(error);
    
    return [driver_ toggleFullScreenOnWindow:[window ref_] error:error];
}


@end

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
@implementation ShiftItWindowManager

- (id)initWithDriver:(id<WindowDriver>)driver {
    FMTAssertNotNil(driver);
    
	if (![super init]) {
		return nil;
	}
    
    driver_ = [driver retain];
    
	return self;
}

- (void) dealloc {	
    [driver_ release];
    
	[super dealloc];
}

- (BOOL) executeAction:(AbstractShiftItAction *)action error:(NSError **)error {
	FMTAssertNotNil(action);

    DefaultWindowContext *ctx = [[[DefaultWindowContext alloc] initWithDriver:driver_] autorelease];
    NSError *cause = nil;
    
    // TODO: in try catch
    if (![action execute:ctx error:&cause]) {
        *error = SICreateErrorWithCause(FMTStr(@"Failed to execute action: %@", [action label]), kWindowManagerFailureErrorCode, cause);
        
        return NO;
    }
    
    return YES;
}


/**
 * Chooses the best screen for the given window rect (screen coord).
 *
 * For each screen it computes the intersecting rectangle and its size. 
 * The biggest is the screen where is the most of the window hence the best fit.
 */
+ (SIScreen *) chooseScreenForWindowGeometry_:(NSRect)geometry {
	NSScreen *fitScreen = [NSScreen mainScreen];
	float maxSize = 0;
	
	for (NSScreen *screen in [NSScreen screens]) {
		NSRect screenRect = [screen frame];
		// need to convert coordinates
		COCOA_TO_SCREEN_COORDINATES(screenRect);
		
		NSRect intersectRect = NSIntersectionRect(screenRect, geometry);
		
		if (intersectRect.size.width > 0 ) {
			float size = intersectRect.size.width * intersectRect.size.height;
			if (size > maxSize) {
				fitScreen = screen;
				maxSize = size;
			}
		}
	}
	
	return [SIScreen screenFromNSScreen:fitScreen];
}

@end