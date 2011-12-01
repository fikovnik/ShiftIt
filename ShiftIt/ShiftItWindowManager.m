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
#import "AXWindowDriver.h"
#import "ShiftIt.h"

extern short GetMBarHeight(void);

// error related
NSString *const SIErrorDomain = @"org.shiftitapp.shifit.error";

NSInteger const kWindowManagerFailureErrorCode = 20101;
NSInteger const kShiftItActionFailureErrorCode = 20103;
NSInteger const kShiftItManagerFailureErrorCode = 2014;

@implementation NSScreen (Extras)

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

- (NSRect)screenFrame {
    NSRect r = [self frame];
    COCOA_TO_SCREEN_COORDINATES(r);
    return  r;
}

- (NSRect)screenVisibleFrame {
    NSRect r = [self visibleFrame];
    COCOA_TO_SCREEN_COORDINATES(r);
    return  r;
}

@end

#pragma mark SI Screen

@implementation SIScreen

@dynamic size;
@dynamic primary;
@dynamic rect;
@dynamic visibleRect;

- (id) initWithNSScreen:(NSScreen *)screen {
	FMTAssertNotNil(screen);
    
	if (![super init]) {
		return nil;
	}
    
    screen_ = screen;
    
	return self;
}

- (BOOL) primary {
    return [screen_ isPrimary];
}

- (NSRect) rect {
	// screen coordinates of the best fit window
	NSRect r = [screen_ screenFrame];

    return r;
}

- (NSRect) visibleRect {
	// visible screen coordinates of the best fit window
	// the visible screen denotes some inner rect of the screen frame
	// which is visible - not occupied by menu bar or dock
	NSRect r = [screen_ screenVisibleFrame];

    return r;    
}

- (NSSize) size {
	return [self visibleRect].size;
}

- (NSString *) description {
    NSDictionary *info = [screen_ deviceDescription];
    
    return FMTStr(@"id=%@, primary=%d, rect=(%@) visibleRect=(%@)", [info objectForKey: @"NSScreenNumber"], [self primary], RECT_STR([self rect]), RECT_STR([self visibleRect]));
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

@end

#pragma mark WindowInfo implementation

@interface SIWindowInfo ()

- (id) initWithPid:(pid_t)pid wid:(CGWindowID)wid rect:(NSRect)rect;

@end

@implementation SIWindowInfo

@synthesize pid = pid_;
@synthesize wid = wid_;
@synthesize rect = rect_;

- (id) initWithPid:(pid_t)pid wid:(CGWindowID)wid rect:(NSRect)rect {
    if (![self init]) {
        return nil;
    }
    
    pid_ = pid;
    wid_ = wid;
    rect_ = rect;
    
    return self;
}

+ (SIWindowInfo *) windowInfoFromCGWindowInfoDictionary:(NSDictionary *)windowInfo {
    FMTAssertNotNil(windowInfo);
    
    NSRect rect;
    CGRectMakeWithDictionaryRepresentation((CFDictionaryRef)[windowInfo objectForKey:(id)kCGWindowBounds], 
                                           (struct CGRect *)&rect);
    
    return [[SIWindowInfo alloc] initWithPid:[[windowInfo objectForKey:(id)kCGWindowOwnerPID] integerValue]
                                         wid:[[windowInfo objectForKey:(id)kCGWindowNumber] integerValue]
                                        rect:rect];
}

- (NSString *) description {
    NSString *bounds = RECT_STR(rect_);
    return FMTStr(@"wid=%d pid=%d rect=(%@)", wid_, pid_, bounds);
}

@end

#pragma mark Default Window Context

@interface DefaultWindowContext : NSObject<WindowContext> {
 @private
    NSArray *drivers_;
    int menuBarHeight_;

    NSMutableArray *windows_;
}

- (id) initWithDrivers:(NSArray *)drivers;

@end

@implementation DefaultWindowContext

- (id) initWithDrivers:(NSArray *)drivers {
    FMTAssertNotNil(drivers);
    
    if (![self init]) {
        return nil;
    }
    
    drivers_ = [drivers retain];
    windows_ = [[NSMutableArray alloc] init];
    menuBarHeight_ = GetMBarHeight();

    // dump screen info
    FMTInDebugOnly(^{
        int screenNo = 0;
        
        for (NSScreen *nsscreen in [NSScreen screens]) {
            SIScreen *screen = [SIScreen screenFromNSScreen:nsscreen];
            FMTLogDebug(@"screen[%d]: %@", screenNo++, screen);
        }        
    });

    return self;
}

- (void) dealloc {
    for (id<SIWindow> window in windows_) {
        [window release];
    }
    
    [windows_ release];
    [drivers_ release];
    
    [super dealloc];
}

- (BOOL) getFocusedWindow:(id<SIWindow> *)window error:(NSError **)error {
    // get all windows order front to back
    NSArray *allWindowsInfoList = (NSArray *) CGWindowListCopyWindowInfo(kCGWindowListOptionOnScreenOnly + kCGWindowListExcludeDesktopElements, 
                                                                      kCGNullWindowID);
    // filter only real windows - layer 0
    NSArray *windowInfoList = [allWindowsInfoList filter:^BOOL(NSDictionary *item) {
        return [[item objectForKey:(id)kCGWindowLayer] integerValue] == 0;
    }];
    
    // get the first one - the front most window
    if ([windowInfoList count] == 0) {
        *error = SICreateError(kWindowManagerFailureErrorCode, @"Unable to find front window");
        return NO;        
    }
    SIWindowInfo *frontWindowInfo = [SIWindowInfo windowInfoFromCGWindowInfoDictionary:[windowInfoList objectAtIndex:0]];
    
    // extract properties
    
    FMTLogDebug(@"Found front window: %@", [frontWindowInfo description]);
    
    __block id<SIWindow> w = nil;
    [drivers_ each:^BOOL(id<WindowDriver> driver) {
        NSError *problem = nil;
        if (![driver findFocusedWindow:&w withInfo:frontWindowInfo error:&problem]) {
            FMTLogDebug(@"Driver %@ did not locate window: %@", [driver description], [problem fullDescription]);
            return YES; /// continue
        } else {
            return NO;
        }
    }];
    
    if (w == nil) {
        *error = SICreateError(kWindowManagerFailureErrorCode, @"Unable to find focused window owner");
        return NO;        
    } else {
        FMTLogDebug(@"Driver mapped window: %@", [w description]);
    }
    
    [allWindowsInfoList release];
    
    *window = w;
    [windows_ addObject:[*window retain]];
    
    return YES;
}

- (BOOL)getAnchorMargins:(int *)leftMargin topMargin:(int *)topMargin bottomMargin:(int *)bottomMargin rightMargin:(int *)rightMargin {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    (*leftMargin) = [defaults integerForKey:kLeftMarginPrefKey];
    (*topMargin) = [defaults integerForKey:kTopMarginPrefKey];
    (*bottomMargin) = [defaults integerForKey:kBottomMarginPrefKey];
    (*rightMargin) = [defaults integerForKey:kRightMarginPrefKey];
}

- (BOOL) anchorWindow:(id<SIWindow>)window error:(NSError **)error {
    NSRect geometry;
    SIScreen *screen;
    NSError *cause = nil;

    if (![window getGeometry:&geometry screen:&screen error:&cause]) {
        *error = SICreateErrorWithCause(kShiftItManagerFailureErrorCode, cause, @"Unable to get window geometry");
        return NO;
    }

    NSSize screenSize = [screen size];

    int leftMargin;
    int topMargin;
    int bottomMargin;
    int rightMargin;
    [self getAnchorMargins:&leftMargin topMargin:&topMargin bottomMargin:&bottomMargin rightMargin:&rightMargin];

    int anchor = 0;

    // determine whether we should anchor the window
    if (geometry.origin.x <= leftMargin) {
        anchor |= kLeftDirection;
    }
    if (geometry.origin.y <= topMargin) {
        anchor |= kTopDirection;
    }
    if (geometry.origin.y + geometry.size.height >= screenSize.height - bottomMargin) {
        anchor |= kBottomDirection;
    }
    if (geometry.origin.x + geometry.size.width >= screenSize.width - rightMargin) {
        anchor |= kRightDirection;
    }

    // adjust anchors if needed
    if (anchor & kLeftDirection) {
        geometry.origin.x = 0;
    }
    if (anchor & kTopDirection) {
        geometry.origin.y = 0;
    }
    if (anchor & kBottomDirection && !(anchor & kTopDirection)) {
        geometry.origin.y = screenSize.height - geometry.size.height;
    }
    if (anchor & kRightDirection && !(anchor & kLeftDirection)) {
        geometry.origin.x = screenSize.width - geometry.size.width;
    }

    if (anchor) {
        FMTLogInfo(@"Anchoring window to: %d : %@", anchor, RECT_STR(geometry));
    }

    if (![window setGeometry:geometry screen:screen error:&cause]) {
        *error = SICreateErrorWithCause(kShiftItManagerFailureErrorCode, cause, @"Unable to set window geometry");
        return NO;
    }

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

- (id) initWithDrivers:(NSArray *)drivers {
    FMTAssertNotNil(drivers);
    
	if (![super init]) {
		return nil;
	}
    
    drivers_ = [drivers retain];
    
	return self;
}

- (void) dealloc {	
    [drivers_ release];
    
	[super dealloc];
}

- (BOOL) executeAction:(id<ShiftItActionDelegate>)action error:(NSError **)error {
	FMTAssertNotNil(action);

    DefaultWindowContext *ctx = [[[DefaultWindowContext alloc] initWithDrivers:drivers_] autorelease];
    
    // TODO: in try catch
    if (![action execute:ctx error:error]) {        
        return NO;
    }
    
    return YES;
}

@end
