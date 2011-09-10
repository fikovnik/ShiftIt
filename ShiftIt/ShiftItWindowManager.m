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
#import "FMTNSArray+Extras.h"

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

@end

#pragma mark SI Screen

@implementation SIScreen

@dynamic size;
@synthesize primary = primary_;
@synthesize screenRect = screenRect_;
@synthesize visibleRect = visibleRect_;

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

/**
 * Chooses the best screen for the given window rect (screen coord).
 *
 * For each screen it computes the intersecting rectangle and its size. 
 * The biggest is the screen where is the most of the window hence the best fit.
 */
+ (SIScreen *) screenForWindowGeometry:(NSRect)geometry {
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

- (NSSize) size {
	return visibleRect_.size;
}

@end

#pragma mark Default Window Context

@interface DefaultWindowContext : NSObject<WindowContext> {
 @private
    id<WindowDriver> driver_;
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
    for (id<SIWindow> window in windows_) {
        [window release];
    }
    
    [windows_ release];
    [driver_ release];
    
    [super dealloc];
}

- (BOOL) getFocusedWindow:(id<SIWindow> *)window error:(NSError **)error {
    
    FMTLogDebug(@"Looking for front process");
    ProcessSerialNumber psn;
    if (GetFrontProcess(&psn) == procNotFound) {
        *error = SICreateError(kWindowManagerFailureErrorCode, @"Unable to find front process");
        return NO;
    }
    
    pid_t pid;
    GetProcessPID(&psn, &pid);

    FMTLogDebug(@"Found front process with pid: %d", pid);
        
    FMTLogDebug(@"Searching driver: %@ for focused window of pid: %d", [driver_ description], pid);
    NSError *cause = nil;
    if (![driver_ findFocusedWindow:window ofPID:pid error:&cause]) {
        *error = SICreateErrorWithCause(kWindowManagerFailureErrorCode, cause, @"Unable to find focused window for PID: %d", pid);
        return NO;
    }
    
    // find wid
    NSRect geometry;
    // if there is a chance that there are drawers we need to get the geometry
    // without as each drawer is actually a windows on itws own
    if ([*window respondsToSelector:@selector(getWindowRect:drawersRect:error:)]) {
        NSRect unused;
        if (![*window getWindowRect:&geometry drawersRect:&unused error:&cause]) {
            *error = SICreateErrorWithCause(kWindowManagerFailureErrorCode, cause, @"Unable to get focused window geometry");
            return NO;        
        }        
    } else {
        if (![*window getGeometry:&geometry error:&cause]) {
            *error = SICreateErrorWithCause(kWindowManagerFailureErrorCode, cause, @"Unable to get focused window geometry");
            return NO;        
        }
    }
    
	NSArray *windowsInfoList = (NSArray *) CGWindowListCopyWindowInfo(kCGWindowListOptionOnScreenOnly + kCGWindowListExcludeDesktopElements, 
                                                                      kCGNullWindowID);
    NSDictionary *windowInfo = [windowsInfoList findFirst:^BOOL(NSDictionary *item) {
        pid_t wPid = [[item objectForKey:(id)kCGWindowOwnerPID] integerValue];
        NSRect rect;
        CGRectMakeWithDictionaryRepresentation((CFDictionaryRef)[item objectForKey:(id)kCGWindowBounds], &rect);

        return wPid == pid && NSEqualRects(rect, geometry);
    }];
    
    if (!windowInfo) {
        *error = SICreateError(kWindowManagerFailureErrorCode, @"Unable to find any window for pid: %d", pid);
        return NO;
    }
    
    CGWindowID wid = [[windowInfo objectForKey:(id)kCGWindowNumber] integerValue];
    
    FMTLogDebug(@"Associated wid: %d", wid);

    [windowsInfoList release];
    
    [windows_ addObject:[*window retain]];
    
    return YES;
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
    
    // TODO: in try catch
    if (![action execute:ctx error:error]) {        
        return NO;
    }
    
    return YES;
}

@end