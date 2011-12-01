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

#import "DefaultShiftItActions.h"
#import "ShiftItApp.h"
#import "FMTDefines.h"
#import "ShiftItWindowManager.h"
#import "WindowGeometryShiftItAction.h"

const SimpleWindowGeometryChangeBlock shiftItLeft = ^NSRect(NSRect windowRect, NSSize screenSize) {
    NSRect r;

    r.origin.x = 0;
    r.origin.y = 0;

    r.size.width = screenSize.width / 2;
    r.size.height = screenSize.height;

    return r;
};

const SimpleWindowGeometryChangeBlock shiftItRight = ^NSRect(NSRect windowRect, NSSize screenSize) {
    NSRect r;

    r.origin.x = screenSize.width / 2;
    r.origin.y = 0;

    r.size.width = screenSize.width / 2;
    r.size.height = screenSize.height;

    return r;
};

const SimpleWindowGeometryChangeBlock shiftItTop = ^NSRect(NSRect windowRect, NSSize screenSize) {
    NSRect r;

    r.origin.x = 0;
    r.origin.y = 0;

    r.size.width = screenSize.width;
    r.size.height = screenSize.height / 2;

    return r;
};

const SimpleWindowGeometryChangeBlock shiftItBottom = ^NSRect(NSRect windowRect, NSSize screenSize) {
    NSRect r;

    r.origin.x = 0;
    r.origin.y = screenSize.height / 2;

    r.size.width = screenSize.width;
    r.size.height = screenSize.height / 2;

    return r;
};

const SimpleWindowGeometryChangeBlock shiftItTopLeft = ^NSRect(NSRect windowRect, NSSize screenSize) {
    NSRect r;

    r.origin.x = 0;
    r.origin.y = 0;

    r.size.width = screenSize.width / 2;
    r.size.height = screenSize.height / 2;

    return r;
};

const SimpleWindowGeometryChangeBlock shiftItTopRight = ^NSRect(NSRect windowRect, NSSize screenSize) {
    NSRect r;

    r.origin.x = screenSize.width / 2;
    r.origin.y = 0;

    r.size.width = screenSize.width / 2;
    r.size.height = screenSize.height / 2;

    return r;
};

const SimpleWindowGeometryChangeBlock shiftItBottomLeft = ^NSRect(NSRect windowRect, NSSize screenSize) {
    NSRect r;

    r.origin.x = 0;
    r.origin.y = screenSize.height / 2;

    r.size.width = screenSize.width / 2;
    r.size.height = screenSize.height / 2;

    return r;
};

const SimpleWindowGeometryChangeBlock shiftItBottomRight = ^NSRect(NSRect windowRect, NSSize screenSize) {
    NSRect r;

    r.origin.x = screenSize.width / 2;
    r.origin.y = screenSize.height / 2;

    r.size.width = screenSize.width / 2;
    r.size.height = screenSize.height / 2;

    return r;
};

const SimpleWindowGeometryChangeBlock shiftItFullScreen = ^NSRect(NSRect windowRect, NSSize screenSize) {
    NSRect r;

    r.origin.x = 0;
    r.origin.y = 0;

    r.size.width = screenSize.width;
    r.size.height = screenSize.height;

    return r;
};

const SimpleWindowGeometryChangeBlock shiftItCenter = ^NSRect(NSRect windowRect, NSSize screenSize) {
    NSRect r;

    r.origin.x = (screenSize.width / 2) - (windowRect.size.width / 2);
    r.origin.y = (screenSize.height / 2) - (windowRect.size.height / 2);

    r.size = windowRect.size;

    return r;
};

@implementation IncreaseReduceShiftItAction

- (id)initWithMode:(BOOL)increase {
    
    if (![self init]) {
        return nil;
    }

    increase_ = increase;
    
    return self;
}

- (NSRect)shiftWindowRect:(NSRect)windowRect screenSize:(NSSize)screenSize withContext:(id<WindowContext>)windowContext {
    float kw = 0;
    float kh = 0;

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    // get the size delta settings - in pixels
    int sizeDeltaType = [defaults integerForKey:kSizeDeltaTypePrefKey];
    float coef = 0;
    switch (sizeDeltaType) {
        case kFixedSizeDeltaType:
            kw = [defaults integerForKey:kFixedSizeWidthDeltaPrefKey];
            kh = [defaults integerForKey:kFixedSizeHeightDeltaPrefKey];
            break;
        case kWindowSizeDeltaType:
            coef = [defaults floatForKey:kWindowSizeDeltaPrefKey] / 100;
            kw = windowRect.size.width * coef;
            kh = windowRect.size.height * coef;
            break;
        case kScreenSizeDeltaType:
            coef = [defaults floatForKey:kScreenSizeDeltaPrefKey] / 100;
            kw = screenSize.width * coef;
            kh = screenSize.height * coef;
            break;
        default:
            break;
    }

    if (kw <= 0) {
        FMTLogError(@"Invalid size for width delta: %f (type: %d)", kw, sizeDeltaType);
        return windowRect;
    }

    if (kh <= 0) {
        FMTLogError(@"Invalid size for height delta: %f (type: %d)", kh, sizeDeltaType);
        return windowRect;
    }

    int leftMargin = 0;
    int topMargin = 0;
    int bottomMargin = 0;
    int rightMargin = 0;

    [windowContext getAnchorMargins:&leftMargin topMargin:&topMargin bottomMargin:&bottomMargin rightMargin:&rightMargin];
    
    // target window rect
    NSRect r = windowRect;
    // 1: increase, -1: reduce
    int inc = increase_ ? 1 : -1;
    // into which direction we are going to increase/reduce size
    int directions = kLeftDirection | kTopDirection | kBottomDirection | kRightDirection;

    if (r.origin.x <= leftMargin) {
        // do not resize to left
        directions ^= kLeftDirection;
    }
    if (r.origin.y <= topMargin) {
        // do not resize to top
        directions ^= kTopDirection;
    }
    if (r.origin.y + r.size.height >= screenSize.height - bottomMargin) {
        // do not resize to bottom
        directions ^= kBottomDirection;
    }
    if (r.origin.x + r.size.width >= screenSize.width - rightMargin) {
        // do not resize to right
        directions ^= kRightDirection;
    }

    // following first handle maximize
    // iff the window is in maximize than allow reducing the size with no
    // anchors
    if (!directions && !increase_) {
        directions = kLeftDirection | kTopDirection | kBottomDirection | kRightDirection;
    }

    // max horizontal resize at a time is kw, so in case we do resize both
    // directions at the same time we do half to each
    int khorz = inc * kw;
    if (directions & kLeftDirection
            && directions & kRightDirection) {
        khorz /= 2;
    }

    // max vertical resize at a time is kh, so in case we do resize both
    // directions at the same time we do half to each
    int kvert = inc * kh;
    if (directions & kTopDirection
            && directions & kBottomDirection) {
        kvert /= 2;
    }

    // adjust the size accordingly into each allowed direction
    if (directions & kLeftDirection) {
        r.origin.x -= khorz; // move left
        r.size.width += khorz; // resize
    }
    if (directions & kTopDirection) {
        r.origin.y -= kvert; // move up
        r.size.height += kvert; // resize
    }
    if (directions & kBottomDirection) {
        r.size.height += kvert; // resize
    }
    if (directions & kRightDirection) {
        r.size.width += khorz; // resize
    }

    // check window rect - constrained by the screen size
    r.size.width = r.size.width < kw ? kw : r.size.width;
    r.size.width = r.size.width > screenSize.width ? screenSize.width : r.size.width;

    r.size.height = r.size.height < kh ? kh : r.size.height;
    r.size.height = r.size.height > screenSize.height ? screenSize.height : r.size.height;

    r.origin.x = r.origin.x < 0 ? 0 : r.origin.x;
    r.origin.x = r.origin.x > screenSize.width - r.size.width ? screenSize.width - r.size.width : r.origin.x;

    r.origin.y = r.origin.y < 0 ? 0 : r.origin.y;
    r.origin.y = r.origin.y > screenSize.height - r.size.height ? screenSize.height - r.size.height : r.origin.y;

    return r;    
}


@end

@implementation ToggleZoomShiftItAction

- (BOOL)execute:(id <WindowContext>)windowContext error:(NSError **)error {
    FMTAssertNotNil(windowContext);
    FMTAssertNotNil(error);

    NSError *cause = nil;
    id <SIWindow> window = nil;

    if (![windowContext getFocusedWindow:&window error:&cause]) {
        *error = SICreateErrorWithCause(kShiftItActionFailureErrorCode,
        cause,
        @"Unable to get active window");
        return NO;
    }

    BOOL flag = NO;
    if (![window canZoom:&flag error:&cause]) {
        *error = SICreateErrorWithCause(kShiftItActionFailureErrorCode,
        cause,
        @"Unable to find out if window can zoom");
    }
    if (!flag) {
        *error = SICreateError(kShiftItActionFailureErrorCode, @"Window cannot zoom");
        return NO;
    }

    if (![window toggleZoom:error]) {
        return NO;
    }

    return YES;
}

@end

@implementation ToggleFullScreenShiftItAction

- (BOOL)execute:(id <WindowContext>)windowContext error:(NSError **)error {
    FMTAssertNotNil(windowContext);
    FMTAssertNotNil(error);

    NSError *cause = nil;
    id <SIWindow> window = nil;

    if (![windowContext getFocusedWindow:&window error:&cause]) {
        *error = SICreateErrorWithCause(kShiftItActionFailureErrorCode,
        cause,
        @"Unable to get active window");
        return NO;
    }

    BOOL flag = NO;
    if (![window canEnterFullScreen:&flag error:&cause]) {
        *error = SICreateErrorWithCause(kShiftItActionFailureErrorCode,
        cause,
        @"Unable to find out if window can enter fullscreen");
    }
    if (!flag) {
        *error = SICreateError(kShiftItActionFailureErrorCode, @"Window cannot enter fullscreen");
        return NO;
    }

    if (![window toggleFullScreen:error]) {
        return NO;
    }

    return YES;
}

@end
