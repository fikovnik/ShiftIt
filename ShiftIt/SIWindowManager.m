/*
 ShiftIt: Window Organizer for OSX
 Copyright (c) 2010-2011 Filip Krikava

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

#import "SIWindowManager.h"

extern short GetMBarHeight(void);

// error related
NSString *const SIErrorDomain = @"org.shiftitapp.shifit.error";

NSInteger const kWindowManagerFailureErrorCode = 20101;
NSInteger const kShiftItActionFailureErrorCode = 20103;
NSInteger const kShiftItManagerFailureErrorCode = 2014;

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
    
    return [[SIWindowInfo alloc] initWithPid:[[windowInfo objectForKey:(id)kCGWindowOwnerPID] intValue]
                                         wid:[[windowInfo objectForKey:(id)kCGWindowNumber] intValue]
                                        rect:rect];
}

- (NSString *) description {
    NSString *bounds = RECT_STR(rect_);
    return FMTStr(@"wid=%d pid=%d rect=(%@)", wid_, pid_, bounds);
}

@end

#pragma mark Default Window Context

@interface DefaultWindowContext : NSObject<SIWindowContext> {
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
    [drivers_ each:^BOOL(id<SIWindowDriver> driver) {
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

- (void) getAnchorMargins:(Margins *)margins {
    // TODO: IOC!
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    (margins->left) = [defaults integerForKey:kLeftMarginPrefKey];
    (margins->top) = [defaults integerForKey:kTopMarginPrefKey];
    (margins->bottom) = [defaults integerForKey:kBottomMarginPrefKey];
    (margins->right) = [defaults integerForKey:kRightMarginPrefKey];
}

- (BOOL)anchorWindow:(id <SIWindow>)window to:(int)anchor error:(NSError **)error {
    // TODO: IOC!
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    // TODO: initialize all rect to empty rect
    NSRect geometry;
    SIScreen *screen = nil;
    NSError *cause = nil;

    if (![window getGeometry:&geometry screen:&screen error:&cause]) {
        *error = SICreateErrorWithCause(kShiftItManagerFailureErrorCode, cause, @"Unable to get window geometry");
        return NO;
    }

    FMTLogDebug(@"Window geometry before anchoring (1. attempt) %@", RECT_STR(geometry));

    // TODO: this is bad, but the quickest way that seems to fix it [#76]
    // TODO: the whole AX API seems to be sensitive when called too often
    // TODO: turn it into a semaphor - block the calls
    [NSThread sleepForTimeInterval:.3];

    if (![window getGeometry:&geometry screen:&screen error:&cause]) {
        *error = SICreateErrorWithCause(kShiftItManagerFailureErrorCode, cause, @"Unable to get window geometry");
        return NO;
    }

    FMTLogDebug(@"Window geometry before anchoring (2. attempt) %@", RECT_STR(geometry));

    NSSize screenSize = [screen size];

    if ([defaults boolForKey:kMarginsEnabledPrefKey]) {
        Margins margins;

        [self getAnchorMargins:&margins];

        // determine whether we should anchor the window
        // we need to use >= otherwise we might loose the anchor in favor of the opposite one
        if (geometry.origin.x >= 0 && geometry.origin.x <= margins.left) {
            anchor |= kLeftDirection;
        }
        if (geometry.origin.y >= 0 && geometry.origin.y <= margins.top) {
            anchor |= kTopDirection;
        }
        if (geometry.origin.x + geometry.size.width < screenSize.width && geometry.origin.x + geometry.size.width >= screenSize.width - margins.right) {
            anchor |= kRightDirection;
        }
        if (geometry.origin.y + geometry.size.height < screenSize.height && geometry.origin.y + geometry.size.height >= screenSize.height - margins.bottom) {
            anchor |= kBottomDirection;
        }
    } else {
        FMTLogDebug(@"Margins are not enabled enabled");
    }

    NSRect newGeometry = geometry;

    if (anchor & kLeftDirection) {
        newGeometry.origin.x = 0;
    }
    if (anchor & kTopDirection) {
        newGeometry.origin.y = 0;
    }
    if (anchor & kBottomDirection && !(anchor & kTopDirection)) {
        newGeometry.origin.y = screenSize.height - geometry.size.height;
    }
    if (anchor & kRightDirection && !(anchor & kLeftDirection)) {
        newGeometry.origin.x = screenSize.width - geometry.size.width;
    }

    if (!NSEqualRects(newGeometry, geometry)) {
        FMTLogInfo(@"Anchoring window to: %d : %@", anchor, RECT_STR(newGeometry));

        if (![window setGeometry:newGeometry screen:screen error:&cause]) {
            *error = SICreateErrorWithCause(kShiftItManagerFailureErrorCode, cause, @"Unable to set window geometry");
            return NO;
        }
    } else {
        FMTLogDebug(@"No anchorning required (geometry is the same)");
    }

    return YES;
}

@end

@implementation SIWindowManager

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

- (BOOL) executeAction:(id<SIActionDelegate>)action error:(NSError **)error {
	FMTAssertNotNil(action);

    DefaultWindowContext *ctx = [[[DefaultWindowContext alloc] initWithDrivers:drivers_] autorelease];
    
    // TODO: in try catch
    if (![action execute:ctx error:error]) {        
        return NO;
    }
    
    return YES;
}

@end
