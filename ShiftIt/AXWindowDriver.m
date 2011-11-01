//
//  AXWindowManager.m
//  ShiftIt
//
//  Created by Filip Krikava on 8/27/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Carbon/Carbon.h>
#import "AXWindowDriver.h"
#import "ShiftIt.h"
#import "FMTDefines.h"

// from whatever reason this attribute is missing in the AXAttributeConstants.h
#define kAXFullScreenAttribute  CFSTR("AXFullScreen")

#pragma mark Logging Utils

#define AX_COPY_ATTR_ERROR(attr, ret) SICreateError(kAXFailureErrorCode, @"AXUIElementCopyAttributeValue failure: attribute: %@ error: %d", @#attr, (ret))
#define AX_SET_ATTR_ERROR(attr, ret) SICreateError(kAXFailureErrorCode, @"AXUIElementSetAttributeValue failure: attribute: %@ error: %d", @#attr, (ret))
#define AX_PERF_ACTION_ERROR(action, ret) SICreateError(kAXFailureErrorCode, @"AXUIElementPerformAction failure: action: %@ error: %d", @#action, (ret))
#define AX_IS_ATTR_SETTABLE_ERROR(attr, ret) SICreateError(kAXFailureErrorCode, @"AXUIElementIsAttributeSettable failure: action: %@ error: %d", @#attr, (ret))
#define AX_VALUE_TYPE_ERROR(expected, actual) SICreateError(kAXFailureErrorCode, @"AXTypeError: expected: %@ actual: %@", @#expected, (actual))

#pragma mark Constants

NSInteger const kAXFailureErrorCode = 20102;
NSInteger const kAXWindowDriverErrorCode = 20104;

#pragma mark AX Utils

@interface AXWindowDriver (AXUtils)
+ (BOOL)getFocusedWindow_:(AXUIElementRef *)windowRef ofApplication:(AXUIElementRef)applicationRef error:(NSError **)error;

+ (BOOL)canAttribute_:(CFStringRef)attributeName ofElement:(AXUIElementRef)element change:(BOOL *)changeable error:(NSError **)error;

+ (BOOL)isAttribute_:(CFStringRef)attributeName ofElement:(AXUIElementRef)element present:(BOOL *)flag error:(NSError **)error;

+ (BOOL)pressButton_:(CFStringRef)buttonName ofElement:(AXUIElementRef)element error:(NSError **)error;

+ (BOOL)getOrigin_:(NSPoint *)origin ofElement:(AXUIElementRef)element error:(NSError **)error;

+ (BOOL)getSize_:(NSSize *)size ofElement:(AXUIElementRef)element error:(NSError **)error;

+ (BOOL)getDrawersGeometry_:(NSRect *)geometry ofElement:(AXUIElementRef)windowRef error:(NSError **)error;

+ (BOOL)setSize_:(NSSize)size ofElement:(AXUIElementRef)element error:(NSError **)error;

+ (BOOL)setOrigin_:(NSPoint)origin ofElement:(AXUIElementRef)element error:(NSError **)error;

@end

#pragma mark AXWindow

@interface AXWindow : NSObject <SIWindow> {
@private
    AXUIElementRef ref_;
    AXWindowDriver *driver_;
}

@property(readonly) AXUIElementRef ref_;
@property(readonly) AXWindowDriver *driver_;

- (id)initWithRef:(AXUIElementRef)ref
           driver:(AXWindowDriver *)driver;

@end

#pragma mark Window Delegate Functions

@interface AXWindowDriver (WindowDelegate)

- (BOOL)getGeometry_:(NSRect *)geometry screen:(SIScreen **)screenRef windowRect:(NSRect *)windowRect drawersRect:(NSRect *)drawersRect ofWindow:(AXUIElementRef)windowRef error:(NSError **)error;

- (BOOL)setGeometry_:(NSRect)geometry screen:(SIScreen *)screen ofWindow:(AXUIElementRef)windowRef error:(NSError **)error;

- (void)freeWindow_:(AXUIElementRef)windowRef;

- (BOOL)getFullScreen_:(BOOL *)fullScreen ofWindow:(AXUIElementRef)windowRef error:(NSError **)error;

- (BOOL)toggleZoomOfWindow_:(AXUIElementRef)windowRef error:(NSError **)error;

- (BOOL)toggleFullScreenOfWindow_:(AXUIElementRef)windowRef error:(NSError **)error;

- (BOOL)canResize_:(BOOL *)flag window:(AXUIElementRef)windowRef error:(NSError **)error;

- (BOOL)canMove_:(BOOL *)flag window:(AXUIElementRef)windowRef error:(NSError **)error;

- (BOOL)canZoom_:(BOOL *)flag window:(AXUIElementRef)windowRef error:(NSError **)error;

- (BOOL)canEnterFullScreen_:(BOOL *)flag window:(AXUIElementRef)windowRef error:(NSError **)error;

@end

#pragma mark AXWindow Implementation

@implementation AXWindow

@synthesize ref_;
@synthesize driver_;

- (id)initWithRef:(AXUIElementRef)ref
           driver:(AXWindowDriver *)driver {

    FMTAssertNotNil(ref);
    FMTAssertNotNil(driver);

    if (![super init]) {
        return nil;
    }

    // TODO: check th eownership policy for Core Foundation
    ref_ = ref;
    driver_ = [driver retain];

    return self;
}

- (void)dealloc {
    [driver_ freeWindow_:ref_];

    [driver_ release];

    [super dealloc];
}

- (BOOL)getGeometry:(NSRect *)geometry screen:(SIScreen **)screen error:(NSError **)error {
    FMTAssertNotNil(geometry);
    FMTAssertNotNil(error);

    NSRect unused;

    return [driver_ getGeometry_:geometry screen:screen windowRect:&unused drawersRect:&unused ofWindow:ref_ error:error];
}

- (BOOL)getWindowRect:(NSRect *)windowRect screen:(SIScreen **)screen drawersRect:(NSRect *)drawersRect error:(NSError **)error {
    FMTAssertNotNil(windowRect);
    FMTAssertNotNil(drawersRect);
    FMTAssertNotNil(error);

    NSRect unused;

    return [driver_ getGeometry_:&unused screen:screen windowRect:windowRect drawersRect:drawersRect ofWindow:ref_ error:error];
}

- (BOOL)setGeometry:(NSRect)geometry screen:(SIScreen *)screen error:(NSError **)error {
    return [driver_ setGeometry_:geometry screen:screen ofWindow:ref_ error:error];
}

- (BOOL)canZoom:(BOOL *)flag error:(NSError **)error {
    return [driver_ canZoom_:flag window:ref_ error:error];
}

- (BOOL)canEnterFullScreen:(BOOL *)flag error:(NSError **)error {
    return [driver_ canEnterFullScreen_:flag window:ref_ error:error];
}

- (BOOL)canMove:(BOOL *)flag error:(NSError **)error {
    return [driver_ canMove_:flag window:ref_ error:error];
}

- (BOOL)canResize:(BOOL *)flag error:(NSError **)error {
    return [driver_ canResize_:flag window:ref_ error:error];
}

- (BOOL)getFullScreen:(BOOL *)flag error:(NSError **)error {
    return [driver_ getFullScreen_:flag ofWindow:ref_ error:error];
}

- (BOOL)toggleFullScreen:(NSError **)error {
    return [driver_ toggleFullScreenOfWindow_:ref_ error:error];
}

- (BOOL)toggleZoom:(NSError **)error {
    return [driver_ toggleZoomOfWindow_:ref_ error:error];
}

@end

#pragma mark AX Window Driver Implementation

@implementation AXWindowDriver

@synthesize shouldUseDrawers = shouldUseDrawers_;
@synthesize converge = converge_;
@synthesize delayBetweenOperations = delayBetweenOperations_;

- (id)initWithError:(NSError **)error {
    if (![super init]) {
        return nil;
    }

    // defaults
    shouldUseDrawers_ = YES;
    converge_ = YES;
    delayBetweenOperations_ = 0;

    systemElementRef_ = AXUIElementCreateSystemWide();
    // here is the assert for purpose because the app should not have gone 
    // that far in execution if the AX api is not available
    FMTAssertNotNil(systemElementRef_);

    return self;
}

- (void)dealloc {
    CFRelease(systemElementRef_);
}

- (BOOL)findFocusedWindow:(id <SIWindow> *)window withInfo:(SIWindowInfo *)windowInfo error:(NSError **)error {
    FMTAssertNotNil(error);

    AXUIElementRef appRef = AXUIElementCreateApplication([windowInfo pid]);
    if (appRef == nil) {
        *error = SICreateError(kAXFailureErrorCode, @"Unable to create AXUIElementRef for the application with PID: %d", [windowInfo pid]);
        return NO;
    }

    AXUIElementRef windowRef;
    //get the focused window
    if (![AXWindowDriver getFocusedWindow_:&windowRef ofApplication:appRef error:error]) {
        CFRelease(appRef);
        return NO;
    }

    *window = [[[AXWindow alloc] initWithRef:windowRef driver:self] autorelease];

    CFRelease(appRef);
    return YES;
}

@end

#pragma mark Utility Functions Implementation

@implementation AXWindowDriver (AXUtils)

+ (BOOL)getFocusedWindow_:(AXUIElementRef *)windowRef ofApplication:(AXUIElementRef)applicationRef error:(NSError **)error {
    FMTAssertNotNil(windowRef);
    FMTAssertNotNil(applicationRef);
    FMTAssertNotNil(error);

    AXError ret = kAXFailureErrorCode;

    if ((ret = AXUIElementCopyAttributeValue(applicationRef,
            kAXFocusedWindowAttribute,
            (CFTypeRef *) windowRef)) != kAXErrorSuccess) {
        *error = AX_COPY_ATTR_ERROR(kAXFocusedWindowAttribute, ret);
        return NO;
    }

    return YES;
}

+ (BOOL)pressButton_:(CFStringRef)buttonName ofElement:(AXUIElementRef)element error:(NSError **)error {
    FMTAssertNotNil(buttonName);
    FMTAssertNotNil(element);
    FMTAssertNotNil(error);

    //get the focused application
    AXUIElementRef button = nil;
    AXError ret = 0;

    if ((ret = AXUIElementCopyAttributeValue(element,
            (CFStringRef) buttonName,
            (CFTypeRef *) &button)) != kAXErrorSuccess) {
        *error = AX_COPY_ATTR_ERROR((NSString *) buttonName, ret);
        return NO;
    }

    FMTAssertNotNil(button);

    if ((ret = AXUIElementPerformAction(button, kAXPressAction)) != kAXErrorSuccess) {
        CFRelease(button);
        *error = AX_PERF_ACTION_ERROR(kAXPressAction, ret);
        return NO;
    }

    CFRelease(button);
    return YES;
}

+ (BOOL)isAttribute_:(CFStringRef)attributeName ofElement:(AXUIElementRef)element present:(BOOL *)flag error:(NSError **)error {
    FMTAssertNotNil(attributeName);
    FMTAssertNotNil(element);
    FMTAssertNotNil(flag);
    FMTAssertNotNil(error);

    CFTypeRef value;
    AXError ret = 0;

    if ((ret = AXUIElementCopyAttributeValue(element, kAXSizeAttribute, &value)) != kAXErrorSuccess) {
        *flag = NO;
        return YES;
    }

    CFRelease(value);
    *flag = YES;
    return YES;
}

+ (BOOL)canAttribute_:(CFStringRef)attributeName ofElement:(AXUIElementRef)element change:(BOOL *)changeable error:(NSError **)error {
    FMTAssertNotNil(attributeName);
    FMTAssertNotNil(element);
    FMTAssertNotNil(changeable);
    FMTAssertNotNil(error);

    Boolean isSettable = false;
    AXError ret = 0;

    if ((ret = AXUIElementIsAttributeSettable(element, (CFStringRef) attributeName, &isSettable)) != kAXErrorSuccess) {
        *error = AX_IS_ATTR_SETTABLE_ERROR((NSString *) attributeName, ret);
        return NO;
    }

    *changeable = isSettable == true ? YES : NO;

    return YES;
}

+ (BOOL)getOrigin_:(NSPoint *)origin ofElement:(AXUIElementRef)element error:(NSError **)error {
    FMTAssertNotNil(element);
    FMTAssertNotNil(origin);
    FMTAssertNotNil(error);

    CFTypeRef originRef;
    AXError ret = 0;

    if ((ret = AXUIElementCopyAttributeValue(element, kAXPositionAttribute, &originRef)) != kAXErrorSuccess) {
        *error = AX_COPY_ATTR_ERROR(kAXPositionAttribute, ret);
        return NO;
    }

    FMTAssertNotNil(originRef);

    if (AXValueGetType(originRef) == kAXValueCGPointType) {
        AXValueGetValue(originRef, kAXValueCGPointType, origin);
    } else {
        CFRelease(originRef);
        *error = AX_VALUE_TYPE_ERROR(kAXValueCGPointType, AXValueGetType(originRef));
        return NO;
    }

    CFRelease(originRef);
    return YES;
}

+ (BOOL)getSize_:(NSSize *)size ofElement:(AXUIElementRef)element error:(NSError **)error {
    FMTAssertNotNil(element);
    FMTAssertNotNil(size);
    FMTAssertNotNil(error);

    CFTypeRef sizeRef;
    AXError ret = 0;

    if ((ret = AXUIElementCopyAttributeValue(element, kAXSizeAttribute, &sizeRef)) != kAXErrorSuccess) {
        *error = AX_COPY_ATTR_ERROR(kAXSizeAttribute, ret);
        return NO;
    }

    FMTAssertNotNil(sizeRef);

    if (AXValueGetType(sizeRef) == kAXValueCGSizeType) {
        AXValueGetValue(sizeRef, kAXValueCGSizeType, size);
    } else {
        CFRelease(sizeRef);
        *error = AX_VALUE_TYPE_ERROR(kAXValueCGSizeType, AXValueGetType(sizeRef));
        return NO;
    }

    CFRelease(sizeRef);
    return YES;
}

+ (BOOL)getDrawersGeometry_:(NSRect *)geometry ofElement:(AXUIElementRef)windowRef error:(NSError **)error {
    FMTAssertNotNil(windowRef);
    FMTAssertNotNil(geometry);
    FMTAssertNotNil(error);

    NSArray *children = nil;
    AXError ret = 0;

    // by defult there are none
    *geometry = NSMakeRect(0, 0, 0, 0);

    if ((ret = AXUIElementCopyAttributeValue(windowRef, kAXChildrenAttribute, (CFTypeRef *) &children)) != kAXErrorSuccess) {
        *error = AX_COPY_ATTR_ERROR(kAXChildrenAttribute, ret);
        return NO;
    }

    NSRect r; // for the loop
    BOOL first = YES;
    NSError *cause = nil;

    for (id child in children) {
        NSString *role = nil;

        if ((ret = AXUIElementCopyAttributeValue((AXUIElementRef) child, kAXRoleAttribute, (CFTypeRef *) &role)) != kAXErrorSuccess) {
            *error = AX_COPY_ATTR_ERROR(kAXRoleAttribute, ret);
            return NO;
        }

        if ([role isEqualToString:NSAccessibilityDrawerRole]) {
            if (![AXWindowDriver getOrigin_:&(r.origin) ofElement:(AXUIElementRef) child error:&cause]) {
                *error = SICreateErrorWithCause(kWindowManagerFailureErrorCode, cause, @"AXError: Unable to position of a window drawer");
                return NO;
            }
            if (![AXWindowDriver getSize_:&(r.size) ofElement:(AXUIElementRef) child error:&cause]) {
                *error = SICreateErrorWithCause(kWindowManagerFailureErrorCode, cause, @"AXError: Unable to size of a window drawer");
                return NO;
            }

            if (first) {
                *geometry = r;
                first = NO;
            } else {
                *geometry = NSUnionRect(*geometry, r);
            }
        }

        CFRelease((CFTypeRef) role);
    }

    [children release];
    return YES;
}

+ (BOOL)setSize_:(NSSize)size ofElement:(AXUIElementRef)element error:(NSError **)error {
    FMTAssertNotNil(element);
    FMTAssertNotNil(error);

    CFTypeRef sizeRef = (CFTypeRef) (AXValueCreate(kAXValueCGSizeType, (const void *) &size));
    AXError ret = 0;

    if ((ret = AXUIElementSetAttributeValue(element, kAXSizeAttribute, sizeRef)) != kAXErrorSuccess) {
        *error = AX_SET_ATTR_ERROR(kAXSizeAttribute, ret);
        CFRelease(sizeRef);

        return NO;
    }

    CFRelease(sizeRef);
    return YES;
}

+ (BOOL)setOrigin_:(NSPoint)origin ofElement:(AXUIElementRef)element error:(NSError **)error {
    FMTAssertNotNil(element);
    FMTAssertNotNil(error);

    CFTypeRef originRef = (CFTypeRef) (AXValueCreate(kAXValueCGPointType, (const void *) &origin));
    AXError ret = 0;

    if ((ret = AXUIElementSetAttributeValue(element, kAXPositionAttribute, originRef)) != kAXErrorSuccess) {
        CFRelease(originRef);
        *error = AX_SET_ATTR_ERROR(kAXPositionAttribute, ret);

        return NO;
    }

    CFRelease(originRef);
    return YES;
}

@end

@implementation AXWindowDriver (WindowDelegate)

// TODO: move to FMT
- (BOOL)untilConverge_:(int(^)(NSError **))fce target:(int)target error:(NSError **)error {
    FMTAssert(target >= 0, @"Target for convergence must be non-negative integer");
    // the distance between actual and target origin
    // current
    int c_d = 0;
    // new
    int n_d = 0;
    // previous
    int p_d = 0;

    for (int i = 1; ; i++) {

        // run at least once
        if (i > 1 &&c_d == target) { // converged
                return YES;
        } else if (i > 2 && c_d >= n_d) { // not converging - greater than the last run
                return NO;
        } else if (i > 3 && c_d >= p_d) { // not converging - greater than the one before last
                return NO;
        }

        p_d = n_d;
        n_d = c_d;

        NSError *cause = nil;

        FMTLogDebug(@"Executing %d. attempt", i);
        c_d = fce(&cause);
        if (c_d < 0) {
            *error = cause;
            return NO;
        }
    }
}

- (BOOL)getGeometry_:(NSRect *)geometryRef screen:(SIScreen **)screenRef windowRect:(NSRect *)windowRectRef drawersRect:(NSRect *)drawersRectRef ofWindow:(AXUIElementRef)windowRef error:(NSError **)error {
    NSRect geometry = NSMakeRect(0, 0, 0, 0);
    NSRect windowRect = NSMakeRect(0, 0, 0, 0);
    NSRect drawersRect = NSMakeRect(0, 0, 0, 0);

    if (![AXWindowDriver getOrigin_:&(windowRect.origin) ofElement:windowRef error:error]) {
        return NO;
    }

    if (![AXWindowDriver getSize_:&(windowRect.size) ofElement:windowRef error:error]) {
        return NO;
    }

    if (shouldUseDrawers_) {
        NSError *cause = nil;
        if (![AXWindowDriver getDrawersGeometry_:&drawersRect ofElement:windowRef error:&cause]) {
            geometry = windowRect;
            FMTLogDebug(@"Unable to get window drawers: %@", [cause localizedDescription]);
        } else if (drawersRect.size.width > 0) {
            // there are some drawers            
            geometry = NSUnionRect(windowRect, drawersRect);
        } else {
            geometry = windowRect;
        }
    }

    SIScreen *screen = [SIScreen screenForWindowGeometry:geometry];

    if (geometryRef) {
        *geometryRef = geometry;
    }
    if (windowRectRef) {
        *windowRectRef = windowRect;
    }
    if (drawersRectRef) {
        *drawersRectRef = drawersRect;
    }
    if (screenRef) {
        *screenRef = screen;
    }

    return YES;
}

- (BOOL)setGeometry_:(NSRect)geometry screen:(SIScreen *)screen ofWindow:(AXUIElementRef)windowRef error:(NSError **)error {
    FMTAssertNotNil(windowRef);
    FMTAssertNotNil(error);
    FMTAssertNotNil(screen);

    FMTLogDebug(@"Setting window geometry to: %@ at screen: %@", RECT_STR(geometry), screen);

    __block NSRect currentGeometry;
    SIScreen *currentScreen;
    NSRect windowRect;
    NSRect drawersRect;

    if (![self getGeometry_:&currentGeometry screen:&currentScreen windowRect:&windowRect drawersRect:&drawersRect ofWindow:windowRef error:error]) {
        return NO;
    }

    BOOL hasDrawers = drawersRect.size.width > 0;

    if (hasDrawers) {
        FMTLogDebug(@"Window geometry without drawers: %@", RECT_STR(windowRect));
        FMTLogDebug(@"Drawers geometry: %@", RECT_STR(drawersRect));
    }
    FMTLogDebug(@"Window geometry with drawers: %@", RECT_STR(currentGeometry));

    // the coordinates given in the geometry are relative to the given screen
    // we need to translate them into global coordinates

    // STEP 1: readjust adjust the visibility
    // the geometry is the new application window geometry relative to the screen originating at [0,0]
    // we need to shift it accordingly that is to the origin of the best fit screen (screenRect) and
    // take into account the visible area of such a screen - menu, dock, etc. which is in the visibleScreenRect
    NSRect visibleScreenRect = [screen visibleRect];

    geometry.origin.x += visibleScreenRect.origin.x;
    geometry.origin.y += visibleScreenRect.origin.y;

    // we need to translate from cocoa coordinates
    FMTLogDebug(@"Setting window geometry after readjusting to the screen origin: %@", RECT_STR(geometry));

    // STEP 2: readjust the drawers
    // when moving the drawers are not taken into an account so need to manually
    // adjust the new position and size relative to the rect of drawers
    NSRect newGeometry = geometry;
 
    if (shouldUseDrawers_ && hasDrawers) {
        int dx = windowRect.origin.x - currentGeometry.origin.x;
        int dy = currentGeometry.origin.y - windowRect.origin.y;
        int dw = currentGeometry.size.width - windowRect.size.width;
        int dh = currentGeometry.size.height - windowRect.size.height;

        newGeometry.origin.x += dx;
        newGeometry.origin.y -= dy;
        newGeometry.size.width -= dw;
        newGeometry.size.height -= dh;

        FMTLogDebug(@"Target window geometry after drawers adjustment: %@", RECT_STR(newGeometry));
    }

    int (^resize)(NSError **) = ^(NSError **error) {
        if (NSEqualSizes(currentGeometry.size, newGeometry.size)) {
            FMTLogDebug(@"New size and existing window size are the same - no action");
            return 0;
        }

        NSError *cause = nil;
        // try to resize
        FMTLogDebug(@"Resizing to: %@", SIZE_STR(newGeometry.size));

        if (![AXWindowDriver setSize_:newGeometry.size
                            ofElement:windowRef
                                error:&cause]) {

            *error = SICreateErrorWithCause(kAXWindowDriverErrorCode,
            cause,
            @"Unable to set window size to: %@",
            SIZE_STR(newGeometry.size));
            return -1;
        }

        // TODO: extract and turn into a semaphore
        [NSThread sleepForTimeInterval:delayBetweenOperations_];

        // see what has happened
        if (![self getGeometry_:nil screen:nil windowRect:&currentGeometry
                    drawersRect:nil ofWindow:windowRef
                          error:&cause]) {

            *error = SICreateErrorWithCause(kAXWindowDriverErrorCode,
            cause,
            @"Unable to get window size");
            return -1;
        }

        FMTLogDebug(@"Window resized to: %@", SIZE_STR(currentGeometry.size));
        return (int) SIArea(currentGeometry.size);
    };

    int (^move)(NSError **) = ^(NSError **error) {
        if (NSEqualPoints(currentGeometry.origin, newGeometry.origin)) {
            FMTLogDebug(@"New origin and existing window origin are the same - no action");
            return 0;
        }
        
        NSError *cause = nil;
        // try to move
        FMTLogDebug(@"Moving to: %@", POINT_STR(newGeometry.origin));

        if (![AXWindowDriver setOrigin_:newGeometry.origin
                              ofElement:windowRef
                                  error:&cause]) {

            *error = SICreateErrorWithCause(kAXWindowDriverErrorCode,
            cause,
            @"Unable to set window origin to: %@",
            POINT_STR(newGeometry.origin));
            return -1;
        }

        // TODO: extract and turn into a semaphore
        [NSThread sleepForTimeInterval:delayBetweenOperations_];

        // see what has happened
        if (![self getGeometry_:nil screen:nil windowRect:&currentGeometry
                    drawersRect:nil ofWindow:windowRef
                          error:&cause]) {

            *error = SICreateErrorWithCause(kAXWindowDriverErrorCode,
            cause,
            @"Unable to get window size");
            return -1;
        }

        FMTLogDebug(@"Window moved to: %@", POINT_STR(currentGeometry.origin));
        return (int) SIDistanceBetweenPoints(currentGeometry.origin, newGeometry.origin);
    };

    // workaround for: http://lists.apple.com/archives/accessibility-dev/2011/Aug/msg00031.html
    // in some cases (and almost always with drawers) the window is not
    // re-sized to the right position at the first time. It has to be tried
    // multiple times.
    if (converge_) {
        if (![self untilConverge_:resize target:SIArea(newGeometry.size) error:error] && error) {
            return NO;

        }
        if (![self untilConverge_:move target:0 error:error] && error) {
            return NO;

        }
        if (![self untilConverge_:resize target:SIArea(newGeometry.size) error:error] && error) {
            return NO;

        }
    } else {
        if (!resize(error) && error) {
            return NO;
        }
        if (!move(error) && error) {
            return NO;
        }
        if (!resize(error) && error) {
            return NO;
        }
    }

    // STEP 3: the API only works if the window will fit on the current screen
    return YES;
}

- (void)freeWindow_:(AXUIElementRef)windowRef {
    FMTAssertNotNil(windowRef);

    CFRelease(windowRef);
}

- (BOOL)getFullScreen_:(BOOL *)fullScreen ofWindow:(AXUIElementRef)windowRef error:(NSError **)error {
    FMTAssertNotNil(windowRef);
    FMTAssertNotNil(fullScreen);
    FMTAssertNotNil(error);

    CFBooleanRef fullScreenRef;
    AXError ret = 0;

    if ((ret = AXUIElementCopyAttributeValue(windowRef,
            (CFStringRef) kAXFullScreenAttribute,
            (CFTypeRef *) &fullScreenRef)) != kAXErrorSuccess) {

        *error = AX_COPY_ATTR_ERROR(kAXFullScreenAttribute, ret);
        return NO;
    }

    *fullScreen = fullScreenRef == kCFBooleanTrue ? YES : NO;
    CFRelease(fullScreenRef);

    return YES;
}

- (BOOL)toggleZoomOfWindow_:(AXUIElementRef)windowRef error:(NSError **)error {
    // args asserted in the nested call
    return [AXWindowDriver pressButton_:kAXZoomButtonAttribute ofElement:windowRef error:error];
}

- (BOOL)toggleFullScreenOfWindow_:(AXUIElementRef)windowRef error:(NSError **)error {
    FMTAssertNotNil(windowRef);
    FMTAssertNotNil(error);

    BOOL fullScreen = NO;
    NSError *cause = nil;
    if (![self getFullScreen_:&fullScreen ofWindow:windowRef error:&cause]) {
        *error = SICreateErrorWithCause(kWindowManagerFailureErrorCode, cause, @"AXError: Unable to determine whether window is in full screen or not");
        return NO;
    }

    AXError ret = 0;

    if ((ret = AXUIElementSetAttributeValue(windowRef,
            kAXFullScreenAttribute,
            fullScreen ? kCFBooleanFalse : kCFBooleanTrue)) != kAXErrorSuccess) {
        *error = AX_SET_ATTR_ERROR(kAXFullScreenAttribute, ret);
        return NO;
    }

    return YES;
}

- (BOOL)canResize_:(BOOL *)flag window:(AXUIElementRef)windowRef error:(NSError **)error {
    // args asserted in the nested call
    if (![AXWindowDriver canAttribute_:kAXSizeAttribute ofElement:windowRef change:flag error:error]) {
        return NO;
    }

    return YES;
}

- (BOOL)canMove_:(BOOL *)flag window:(AXUIElementRef)windowRef error:(NSError **)error {
    // args asserted in the nested call
    if (![AXWindowDriver canAttribute_:kAXPositionAttribute ofElement:windowRef change:flag error:error]) {
        return NO;
    }

    return YES;
}

- (BOOL)canZoom_:(BOOL *)flag window:(AXUIElementRef)windowRef error:(NSError **)error {
    // args asserted in the nested call
    if (![AXWindowDriver isAttribute_:kAXZoomButtonAttribute ofElement:windowRef present:flag error:error]) {
        return NO;
    }

    return YES;
}

- (BOOL)canEnterFullScreen_:(BOOL *)flag window:(AXUIElementRef)windowRef error:(NSError **)error {
    // args asserted in the nested call
    if (![AXWindowDriver canAttribute_:kAXFullScreenAttribute ofElement:windowRef change:flag error:error]) {
        return NO;
    }

    return YES;
}


@end
