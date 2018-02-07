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

#import "DefaultShiftItActions.h"
// TODO: extract this to be out of here
#import "ShiftItApp.h"

BOOL CloseTo(double a, double b) {
    return fabs(a - b) < 20;
}

BOOL rectCloseTo(NSRect a, NSRect b) {
    return CloseTo(a.origin.x, b.origin.x) &&
    CloseTo(a.origin.y, b.origin.y) &&
    CloseTo(a.size.height, b.size.height) &&
    CloseTo(a.size.width, b.size.width);
}

const SimpleWindowGeometryChangeBlock shiftItLeft = ^AnchoredRect(NSRect windowRect, NSSize screenSize) {
    double screenWidth = screenSize.width;

    NSRect leftHalf = NSMakeRect(0, 0, 0, 0);
    leftHalf.origin.x = 0;
    leftHalf.origin.y = 0;
    leftHalf.size.width = screenSize.width / 2.0;
    leftHalf.size.height = screenSize.height;

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL cycle = [defaults boolForKey: kMutipleActionsCycleWindowSizes];
    if(!cycle) {
        return MakeAnchoredRect(leftHalf, kLeftDirection);
    }

    NSRect leftThird = NSMakeRect(0, 0, 0, 0);
    leftThird.origin.x = 0;
    leftThird.origin.y = 0;
    leftThird.size.width = floor(screenWidth * 1.0 / 3.0);
    leftThird.size.height = screenSize.height;

    if(rectCloseTo(windowRect, leftHalf)) {
        return MakeAnchoredRect(leftThird, kLeftDirection);
    } else if (rectCloseTo(windowRect, leftThird)) {
        leftHalf.size.width = floor(screenWidth * 2.0 / 3.0);
    }


    return MakeAnchoredRect(leftHalf, kLeftDirection);
};

const SimpleWindowGeometryChangeBlock shiftItRight = ^AnchoredRect(NSRect windowRect, NSSize screenSize) {
    double screenWidth = screenSize.width;

    NSRect rightHalf = NSMakeRect(0, 0, 0, 0);
    rightHalf.origin.x = screenSize.width / 2;
    rightHalf.origin.y = 0;
    rightHalf.size.width = screenSize.width / 2.0;
    rightHalf.size.height = screenSize.height;

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL cycle = [defaults boolForKey: kMutipleActionsCycleWindowSizes];
    if(!cycle) {
        return MakeAnchoredRect(rightHalf, kRightDirection);
    }

    NSRect rightThird = NSMakeRect(0, 0, 0, 0);
    rightThird.origin.x = screenWidth - (screenWidth * 1.0 / 3.0);
    rightThird.origin.y = 0;
    rightThird.size.width = floor(screenWidth * 1.0 / 3.0);
    rightThird.size.height = screenSize.height;

    if(rectCloseTo(windowRect, rightHalf)) {
        FMTLogDebug(@"Close to half!");
        return MakeAnchoredRect(rightThird, kRightDirection);
    } else if (rectCloseTo(windowRect, rightThird)) {
        FMTLogDebug(@"Close to third!");
        rightHalf.origin.x = screenWidth - (screenWidth * 2.0 / 3.0);
        rightHalf.size.width = floor(screenWidth * 2.0 / 3.0);
    }

    return MakeAnchoredRect(rightHalf, kRightDirection);
};

const SimpleWindowGeometryChangeBlock shiftItTop = ^AnchoredRect(NSRect windowRect, NSSize screenSize) {
    double screenHeight = screenSize.height;

    NSRect topHalf = NSMakeRect(0, 0, 0, 0);
    topHalf.origin.x = 0;
    topHalf.origin.y = 0;
    topHalf.size.width = screenSize.width;
    topHalf.size.height = screenSize.height / 2;

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL cycle = [defaults boolForKey: kMutipleActionsCycleWindowSizes];
    if(!cycle) {
        return MakeAnchoredRect(topHalf, kTopDirection);
    }

    NSRect topThird = NSMakeRect(0, 0, 0, 0);
    topThird.origin.x = 0;
    topThird.origin.y = 0;
    topThird.size.width = screenSize.width;
    topThird.size.height = floor(screenHeight * 1.0 / 3.0);

    if(rectCloseTo(windowRect, topHalf)) {
        return MakeAnchoredRect(topThird, kTopDirection);
    } else if (rectCloseTo(windowRect, topThird)) {
        topHalf.size.height = floor(screenHeight * 2.0 / 3.0);
    }

    return MakeAnchoredRect(topHalf, kTopDirection);
};

const SimpleWindowGeometryChangeBlock shiftItBottom = ^AnchoredRect(NSRect windowRect, NSSize screenSize) {
    double screenHeight = screenSize.height;

    NSRect bottomHalf = NSMakeRect(0, 0, 0, 0);
    bottomHalf.origin.x = 0;
    bottomHalf.origin.y = screenSize.height / 2;
    bottomHalf.size.width = screenSize.width;
    bottomHalf.size.height = screenSize.height / 2;

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL cycle = [defaults boolForKey: kMutipleActionsCycleWindowSizes];
    if(!cycle) {
        return MakeAnchoredRect(bottomHalf, kBottomDirection);
    }

    NSRect bottomThird = NSMakeRect(0, 0, 0, 0);
    bottomThird.origin.x = 0;
    bottomThird.origin.y = screenHeight - (screenHeight * 1.0 / 3.0);
    bottomThird.size.width = screenSize.width;
    bottomThird.size.height = floor(screenHeight * 1.0 / 3.0);

    if(rectCloseTo(windowRect, bottomHalf)) {
        return MakeAnchoredRect(bottomThird, kBottomDirection);
    } else if (rectCloseTo(windowRect, bottomThird)) {
        bottomHalf.size.height = floor(screenHeight * 2.0 / 3.0);
        bottomHalf.origin.y = screenHeight - (screenHeight * 2.0 / 3.0);
    }

    return MakeAnchoredRect(bottomHalf, kBottomDirection);
};

const SimpleWindowGeometryChangeBlock shiftItTopLeft = ^AnchoredRect(NSRect windowRect, NSSize screenSize) {
    NSRect r = NSMakeRect(0, 0, 0, 0);

    r.origin.x = 0;
    r.origin.y = 0;

    r.size.width = screenSize.width / 2;
    r.size.height = screenSize.height / 2;

    return MakeAnchoredRect(r, kTopDirection | kLeftDirection);
};

const SimpleWindowGeometryChangeBlock shiftItTopRight = ^AnchoredRect(NSRect windowRect, NSSize screenSize) {
    NSRect r = NSMakeRect(0, 0, 0, 0);

    r.origin.x = screenSize.width / 2;
    r.origin.y = 0;

    r.size.width = screenSize.width / 2;
    r.size.height = screenSize.height / 2;

    return MakeAnchoredRect(r, kTopDirection | kRightDirection);
};

const SimpleWindowGeometryChangeBlock shiftItBottomLeft = ^AnchoredRect(NSRect windowRect, NSSize screenSize) {
    NSRect r = NSMakeRect(0, 0, 0, 0);

    r.origin.x = 0;
    r.origin.y = screenSize.height / 2;

    r.size.width = screenSize.width / 2;
    r.size.height = screenSize.height / 2;

    return MakeAnchoredRect(r, kBottomDirection | kLeftDirection);
};

const SimpleWindowGeometryChangeBlock shiftItBottomRight = ^AnchoredRect(NSRect windowRect, NSSize screenSize) {
    NSRect r = NSMakeRect(0, 0, 0, 0);

    r.origin.x = screenSize.width / 2;
    r.origin.y = screenSize.height / 2;

    r.size.width = screenSize.width / 2;
    r.size.height = screenSize.height / 2;

    return MakeAnchoredRect(r, kBottomDirection | kRightDirection);
};

const SimpleWindowGeometryChangeBlock shiftItFullScreen = ^AnchoredRect(NSRect windowRect, NSSize screenSize) {
    NSRect r = NSMakeRect(0, 0, 0, 0);

    r.origin.x = 0;
    r.origin.y = 0;

    r.size.width = screenSize.width;
    r.size.height = screenSize.height;

    return MakeAnchoredRect(r, 0);
};

const SimpleWindowGeometryChangeBlock shiftItCenter = ^AnchoredRect(NSRect windowRect, NSSize screenSize) {
    NSRect r = NSMakeRect(0, 0, 0, 0);

    r.origin.x = (screenSize.width / 2) - (windowRect.size.width / 2);
    r.origin.y = (screenSize.height / 2) - (windowRect.size.height / 2);

    r.size = windowRect.size;

    return MakeAnchoredRect(r, 0);
};

@implementation IncreaseReduceShiftItAction

- (id)initWithMode:(BOOL)increase {

    if (![self init]) {
        return nil;
    }

    increase_ = increase;

    return self;
}

- (AnchoredRect)shiftWindowRect:(NSRect)windowRect screenSize:(NSSize)screenSize withContext:(id<SIWindowContext>)windowContext {
    double kw = 0;
    double kh = 0;

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    // get the size delta settings - in pixels
    NSInteger sizeDeltaType = [defaults integerForKey:kSizeDeltaTypePrefKey];
    double coef = 0;
    switch (sizeDeltaType) {
        case kFixedSizeDeltaType:
            kw = [defaults integerForKey:kFixedSizeWidthDeltaPrefKey];
            kh = [defaults integerForKey:kFixedSizeHeightDeltaPrefKey];
            break;
        case kWindowSizeDeltaType:
            coef = [defaults doubleForKey:kWindowSizeDeltaPrefKey] / 100;
            kw = windowRect.size.width * coef;
            kh = windowRect.size.height * coef;
            break;
        case kScreenSizeDeltaType:
            coef = [defaults doubleForKey:kScreenSizeDeltaPrefKey] / 100;
            kw = screenSize.width * coef;
            kh = screenSize.height * coef;
            break;
        default:
            break;
    }

    if (kw <= 0) {
        FMTLogError(@"Invalid size for width delta: %f (type: %ld)", kw, sizeDeltaType);
        return MakeAnchoredRect(windowRect, 0);
    }

    if (kh <= 0) {
        FMTLogError(@"Invalid size for height delta: %f (type: %ld)", kh, sizeDeltaType);
        return MakeAnchoredRect(windowRect, 0);
    }

    Margins margins;

    [windowContext getAnchorMargins:&margins];

    // target window rect
    NSRect r = windowRect;
    // 1: increase, -1: reduce
    int inc = increase_ ? 1 : -1;
    // into which direction we are going to increase/reduce size
    int directions = kLeftDirection | kTopDirection | kBottomDirection | kRightDirection;

    if (r.origin.x <= margins.left) {
        // do not resize to left
        directions ^= kLeftDirection;
    }
    if (r.origin.y <= margins.top) {
        // do not resize to top
        directions ^= kTopDirection;
    }
    if (r.origin.y + r.size.height >= screenSize.height - margins.bottom) {
        // do not resize to bottom
        directions ^= kBottomDirection;
    }
    if (r.origin.x + r.size.width >= screenSize.width - margins.right) {
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
    int khorz = (int) (inc * kw);
    if (directions & kLeftDirection
        && directions & kRightDirection) {
        khorz /= 2;
    }

    // max vertical resize at a time is kh, so in case we do resize both
    // directions at the same time we do half to each
    int kvert = (int) (inc * kh);
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
    // TODO: this should got to the WindowGeometryShiftItAction
    r.size.width = (CGFloat) (r.size.width < kw ? kw : r.size.width);
    r.size.width = r.size.width > screenSize.width ? screenSize.width : r.size.width;

    r.size.height = (CGFloat) (r.size.height < kh ? kh : r.size.height);
    r.size.height = r.size.height > screenSize.height ? screenSize.height : r.size.height;

    r.origin.x = r.origin.x < 0 ? 0 : r.origin.x;
    r.origin.x = r.origin.x > screenSize.width - r.size.width ? screenSize.width - r.size.width : r.origin.x;

    r.origin.y = r.origin.y < 0 ? 0 : r.origin.y;
    r.origin.y = r.origin.y > screenSize.height - r.size.height ? screenSize.height - r.size.height : r.origin.y;

    return MakeAnchoredRect(r, !directions);
}


@end

@implementation ToggleZoomShiftItAction

- (BOOL)execute:(id <SIWindowContext>)windowContext error:(NSError **)error {
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

- (BOOL)execute:(id <SIWindowContext>)windowContext error:(NSError **)error {
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

@implementation ScreenChangeShiftItAction {
@private
    BOOL next_;
}

- (id)initWithMode:(BOOL)next {
    if (![super init]) {
        return nil;
    }

    next_ = next;

    return self;
}

- (BOOL)execute:(id <SIWindowContext>)windowContext error:(NSError **)error {
    FMTAssertNotNil(windowContext);
    FMTAssertNotNil(error);

    NSError *cause = nil;
    id<SIWindow> window = nil;
    BOOL flag = NO;

    if(![windowContext getFocusedWindow:&window error:&cause]) {
        *error = SICreateErrorWithCause(kShiftItActionFailureErrorCode,
                                        cause,
                                        @"Unable to get active window");
        return NO;
    }

    if ([window respondsToSelector:@selector(getFullScreen:error:)]) {
        if (![window getFullScreen:&flag error:&cause]) {
            *error = SICreateErrorWithCause(kShiftItActionFailureErrorCode,
                                            cause,
                                            @"Unable to get window fullScreen state");
        }
        if (flag) {
            *error = SICreateError(kShiftItActionFailureErrorCode, @"Windows in fullscreen are not supported");
            return NO;
        }
    }

    NSRect currentGeometry;
    SIScreen *currentScreen;
    if (![window getGeometry:&currentGeometry screen:&currentScreen error:&cause]) {
        *error = SICreateErrorWithCause(kShiftItActionFailureErrorCode,
                                        cause,
                                        @"Unable to get window geometry");
        return NO;
    }

    FMTLogInfo(@"Current window geometry: %@ screen: %@", RECT_STR(currentGeometry), currentScreen);

    NSSize currentScreenSize = [currentScreen size];
    SIScreen *screen = next_ ? [currentScreen nextScreen] : [currentScreen previousScreen];

    if ([screen isEqual:currentScreen]) {
        FMTLogInfo(@"Screens are the same");
        return YES;
    }

    NSSize screenSize = [screen size];

    CGFloat kw = screenSize.width / currentScreenSize.width;
    CGFloat kh = screenSize.height / currentScreenSize.height;

    NSRect geometry = {
        { currentGeometry.origin.x * kw , currentGeometry.origin.y * kh },
        { currentGeometry.size.width * kw , currentGeometry.size.height * kh }
    };

    FMTLogInfo(@"New window geometry: %@ screen %@", RECT_STR(geometry), screen);

    if (![window setGeometry:geometry screen:screen error:&cause]) {
        *error = SICreateErrorWithCause(kShiftItActionFailureErrorCode,
                                        cause,
                                        @"Unable to set new geometry of a window to %@ at screen: %@", RECT_STR(geometry), screen);
        return NO;
    }

    if (![windowContext anchorWindow:window to:0 error:&cause]) {
        *error = SICreateErrorWithCause(kShiftItActionFailureErrorCode,
                                        cause,
                                        @"Unable to anchor window");
        return NO;
    }

    // TODO: make sure window is always visible

    return YES;
}

@end
