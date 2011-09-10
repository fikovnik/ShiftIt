//
//  AXWindowManager.m
//  ShiftIt
//
//  Created by Filip Krikava on 8/27/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

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

// even if the user settings is higher - this defines the absolute max of tries
const int kMaxNumberOfTries = 20;

#pragma mark Utility Functions

@interface AXWindowDriver(AXUtils)

+ (BOOL) canAttribute_:(CFStringRef)attributeName ofElement:(AXUIElementRef)element change:(BOOL *)changeable error:(NSError **)error;
+ (BOOL) pressButton_:(CFStringRef)buttonName ofElement:(AXUIElementRef)element error:(NSError **)error;

+ (BOOL) setElement_:(AXUIElementRef)element size:(NSSize)size error:(NSError **)error;

+ (BOOL) getElement_:(AXUIElementRef)element origin:(NSPoint *)origin error:(NSError **)error;
+ (BOOL) getElement_:(AXUIElementRef)element size:(NSSize *)size error:(NSError **)error;

+ (BOOL) getWindow_:(AXUIElementRef)windowRef geometry:(NSRect *)geometry error:(NSError **)error;
+ (BOOL) getWindow_:(AXUIElementRef)windowRef drawersGeometry:(NSRect *)geometry error:(NSError **)error;

@end

@interface AXWindowDriver(WindowDelegate)
- (BOOL) setWindow_:(id<SIWindow>)window origin:(NSPoint)origin error:(NSError **)error;
- (BOOL) setWindow_:(id<SIWindow>)window size:(NSSize)size error:(NSError **)error;
- (void) freeWindow_:(id<SIWindow>)window;

@end

#pragma mark AXWindow

@interface AXWindow : NSObject<SIWindow> {
@private
    AXUIElementRef ref_;
    AXWindowDriver *driver_;
    
    NSRect windowRect_;
    NSRect drawersRect_;
    NSRect geometry_;
    
    SIScreen *screen_;
}

@property (readonly) AXUIElementRef ref_;
@property (readonly) AXWindowDriver *driver_;

@property (readonly) NSRect windowRect_;
@property (readonly) NSRect drawersRect_;
@property (readonly) BOOL hasDrawers_;

@property (readonly) NSRect geometry;
@property (readonly) NSPoint origin;
@property (readonly) NSSize size;

@property (readonly) SIScreen *screen;

- (id) initWithRef:(AXUIElementRef)ref
            driver:(AXWindowDriver *)driver
        windowRect:(NSRect)windowRect 
       drawersRect:(NSRect)drawersRect 
            screen:(SIScreen *)screen;

@end

#pragma mark AXWindow Implementation

@implementation AXWindow

@synthesize ref_;
@synthesize driver_;

@synthesize windowRect_;
@synthesize drawersRect_;
@dynamic hasDrawers_;

@synthesize geometry = geometry_;
@dynamic origin;
@dynamic size;

@synthesize screen = screen_;

- (id) initWithRef:(AXUIElementRef)ref 
            driver:(AXWindowDriver *)driver
        windowRect:(NSRect)windowRect 
       drawersRect:(NSRect)drawersRect 
            screen:(SIScreen *)screen {
    
	// TODO: check for invalid wids
	FMTAssertNotNil(ref);
	FMTAssertNotNil(screen);
    
	if (![super init]) {
		return nil;
	}
    
    // TODO: check th eownership policy for Core Foundation
	ref_ = ref;
    driver_ = [driver retain];
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
    [driver_ freeWindow_:self];
    
    [driver_ release];
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

// TODO: make sure that the origin makes sense
- (BOOL) moveTo:(NSPoint)origin error:(NSError **)error {
    return [driver_ setWindow_:self origin:origin error:error];
}

// TODO: make sure that the size makes sense
- (BOOL) resizeTo:(NSSize)size error:(NSError **)error {
    return [driver_ setWindow_:self size:size error:error];    
}


@end

#pragma mark AX Window Driver Implementation

static int numberOfTries_ = kMaxNumberOfTries;

@implementation AXWindowDriver

@synthesize shouldUseDrawers = shouldUseDrawers_;

+ (void) initialize {
    numberOfTries_ = [[NSUserDefaults standardUserDefaults] integerForKey:kNumberOfTriesPrefKey];
    if (numberOfTries_ < 0 || numberOfTries_ > kMaxNumberOfTries) {
        numberOfTries_ = 1;
    }
}

- (id)init {
	if(![super init]){
		return nil;
	}
    
    systemElementRef_ = AXUIElementCreateSystemWide();
    // here is the assert for purpose because the app should not have gone 
	// that far in execution if the AX api is not available
	FMTAssertNotNil(systemElementRef_);
    
    // TODO: should be a parameter for the constructor
    shouldUseDrawers_ = [[NSUserDefaults standardUserDefaults] boolForKey:kIncludeDrawersPrefKey];
    
    return self;
}

- (void) dealloc {
    CFRelease(systemElementRef_);
}

- (BOOL) getFocusedWindow:(id<SIWindow> *)window error:(NSError **)error {  
    FMTAssertNotNil(window);
	FMTAssertNotNil(error);
    
    //get the focused application
    AXUIElementRef focusedAppRef = nil;
    AXError ret = kAXErrorFailure;
    
    if ((ret = AXUIElementCopyAttributeValue(systemElementRef_,
                                             kAXFocusedApplicationAttribute,
                                             (CFTypeRef *) &focusedAppRef)) != kAXErrorSuccess) {
        *error = AX_COPY_ATTR_ERROR(kAXFocusedApplicationAttribute, ret);
        return NO;
    }    
    
    FMTAssertNotNil(focusedAppRef);
    
    //get the focused window
    AXUIElementRef windowRef = nil;
    if ((ret = AXUIElementCopyAttributeValue(focusedAppRef,
                                             kAXFocusedWindowAttribute,
                                             (CFTypeRef*) &windowRef)) != kAXErrorSuccess) {
        
        *error = AX_COPY_ATTR_ERROR(kAXFocusedWindowAttribute, ret);
        CFRelease(focusedAppRef);
        return NO;
    }
    
    NSRect windowRect = NSMakeRect(0, 0, 0, 0); // window rect
	NSRect drawersRect = NSMakeRect(0, 0, 0, 0); // drawers of the window
    NSRect geometry;
    
    if (![AXWindowDriver getWindow_:windowRef geometry:&windowRect error:error]) {
        return NO;
    }
    
    FMTLogDebug(@"Window geometry without drawers: %@", RECT_STR(windowRect));
    
    if (shouldUseDrawers_) {
        NSError *cause = nil;
        
        if (![AXWindowDriver getWindow_:windowRef drawersGeometry:&drawersRect error:&cause]) {
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
    
    
    SIScreen *screen = [SIScreen screenForWindowGeometry:geometry];
    *window = [[AXWindow alloc] initWithRef:windowRef driver:self windowRect:windowRect drawersRect:drawersRect screen:screen];
    
    return YES;
}

//- (BOOL) isWindow:(AXWindow *)window inFullScreen:(BOOL *)fullScreen error:(NSError **)error {
//    FMTAssertNotNil(window);
//    FMTAssertNotNil(fullScreen);
//	FMTAssertNotNil(error);
//	
//    CFBooleanRef fullScreenRef;
//    AXError ret = 0;
//    
//    if ((ret = AXUIElementCopyAttributeValue([window ref_],
//                                             (CFStringRef) kAXFullScreenAttribute,
//                                             (CFTypeRef *) &fullScreenRef)) != kAXErrorSuccess) {
//        
//        *error = AX_COPY_ATTR_ERROR(kAXFullScreenAttribute, ret);
//        return NO;
//    }
//    
//    *fullScreen = fullScreenRef == kCFBooleanTrue ? YES : NO;
//	CFRelease(fullScreenRef);
//	
//	return YES;
//}
//
//
//- (BOOL) canWindow:(AXWindow *)window resize:(BOOL *)resizeable error:(NSError **)error {    // args asserted in the nested call
//    // args asserted in the nested call
//    BOOL changeable;
//    
//    if (![AXWindowDriver canAttribute_:kAXSizeAttribute ofElement:[window ref_] change:&changeable error:error]) {
//		return NO;
//    }
//    
//    return YES;
//}
//
//- (BOOL) canWindow:(AXWindow *)window move:(BOOL *)moveable error:(NSError **)error {
//    // args asserted in the nested call
//    BOOL changeable;
//    
//    if (![AXWindowDriver canAttribute_:kAXPositionAttribute ofElement:[window ref_] change:&changeable error:error]) {
//		return NO;
//    }
//    
//    return YES;
//}
//
//- (BOOL) toggleZoomOnWindow:(AXWindow *)window error:(NSError **)error {    
//    // args asserted in the nested call
//    return [AXWindowDriver pressButton_:kAXZoomButtonAttribute ofElement:[window ref_] error:error];
//}
//
//- (BOOL) toggleFullScreenOnWindow:(AXWindow *)window error:(NSError **)error {
//    FMTAssertNotNil(window);
//	FMTAssertNotNil(error);
//	
//    BOOL fullScreen = NO;
//    NSError *cause = nil;
//    if(![self isWindow:window inFullScreen:&fullScreen error:&cause]) {
//        *error = SICreateErrorWithCause(kWindowManagerFailureErrorCode, cause, @"AXError: Unable to determine whether window is in full screen or not");
//        return NO;
//    }
//    
//    AXError ret = 0;
//	
//    if ((ret = AXUIElementSetAttributeValue([window ref_], 
//                                            kAXFullScreenAttribute, 
//                                            fullScreen ? kCFBooleanFalse : kCFBooleanTrue)) != kAXErrorSuccess){
//        *error = AX_SET_ATTR_ERROR(kAXFullScreenAttribute, ret);
//        return NO;
//	}		
//    
//    return YES;
//    
//    //  return [AXWindowDriver pressButton_:kAXFullScreenButtonAttribute ofElement:window error:error];
//}
@end

#pragma mark Utility Functions Implementation

@implementation AXWindowDriver (AXUtils)

+ (BOOL) pressButton_:(CFStringRef)buttonName ofElement:(AXUIElementRef)element error:(NSError **)error {
    FMTAssertNotNil(buttonName);
    FMTAssertNotNil(element);
    FMTAssertNotNil(error);
    
    //get the focused application
    AXUIElementRef button = nil;
    AXError ret = 0;
    
    if ((ret = AXUIElementCopyAttributeValue(element,
                                             (CFStringRef) buttonName,
                                             (CFTypeRef *) &button)) != kAXErrorSuccess) {
        *error = AX_COPY_ATTR_ERROR((NSString *)buttonName, ret);
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

+ (BOOL) canAttribute_:(CFStringRef)attributeName ofElement:(AXUIElementRef)element change:(BOOL *)changeable error:(NSError **)error {
    FMTAssertNotNil(attributeName);
    FMTAssertNotNil(element);
    FMTAssertNotNil(changeable);
    FMTAssertNotNil(error);
    
    Boolean isSettable = false;
    AXError ret = 0;
    
    if ((ret = AXUIElementIsAttributeSettable(element, (CFStringRef)attributeName, &isSettable)) != kAXErrorSuccess) {
        *error = AX_IS_ATTR_SETTABLE_ERROR((NSString *)attributeName, ret);
        return NO;
    }
    
    *changeable = isSettable == true ? YES : NO;
    
    return YES;
}

+ (BOOL) getElement_:(AXUIElementRef)element origin:(NSPoint *)origin error:(NSError **)error {
	FMTAssertNotNil(element);
	FMTAssertNotNil(origin);
	FMTAssertNotNil(error);
    
	CFTypeRef originRef;
    AXError ret = 0;
	
	if ((ret = AXUIElementCopyAttributeValue(element,kAXPositionAttribute, &originRef)) != kAXErrorSuccess) {
        *error = AX_COPY_ATTR_ERROR(kAXPositionAttribute, ret);
		return NO;
	}
	
	FMTAssertNotNil(originRef);
    
	if(AXValueGetType(originRef) == kAXValueCGPointType) {
		AXValueGetValue(originRef, kAXValueCGPointType, origin);
	} else {
		CFRelease(originRef);
        *error = AX_VALUE_TYPE_ERROR(kAXValueCGPointType, AXValueGetType(originRef));
		return NO;
	}
	
	CFRelease(originRef);
	return YES;
}

+ (BOOL) getElement_:(AXUIElementRef)element size:(NSSize *)size error:(NSError **)error {
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
    
	if(AXValueGetType(sizeRef) == kAXValueCGSizeType) {
		AXValueGetValue(sizeRef, kAXValueCGSizeType, size);
	} else {
        CFRelease(sizeRef);
        *error = AX_VALUE_TYPE_ERROR(kAXValueCGSizeType,AXValueGetType(sizeRef));
		return NO;
	}
	
	CFRelease(sizeRef);
	return YES;
}

+ (BOOL) getWindow_:(AXUIElementRef)windowRef geometry:(NSRect *)geometry error:(NSError **)error {
	FMTAssertNotNil(windowRef);
	FMTAssertNotNil(geometry);
	FMTAssertNotNil(error);
	
	if (![AXWindowDriver getElement_:windowRef origin:&(geometry->origin) error:error]) {
		return NO;
	}
    
	if (![AXWindowDriver getElement_:windowRef size:&(geometry->size) error:error]) {
		return NO;
	}
    
    return YES;
}

+ (BOOL) getWindow_:(AXUIElementRef)windowRef drawersGeometry:(NSRect *)geometry error:(NSError **)error {
	FMTAssertNotNil(windowRef);
	FMTAssertNotNil(geometry);
	FMTAssertNotNil(error);
    
	NSArray *children = nil;
    AXError ret = 0;
    
    // by defult there are none
    *geometry = NSMakeRect(0, 0, 0, 0);
    
	if ((ret = AXUIElementCopyAttributeValue(windowRef, kAXChildrenAttribute, (CFTypeRef *)&children)) != kAXErrorSuccess) {
        *error = AX_COPY_ATTR_ERROR(kAXChildrenAttribute, ret);
		return NO;
	}
    
	NSRect r; // for the loop	
	BOOL first = YES;
    NSError *cause = nil;
    
	for (id child in children) {
		NSString *role = nil;
		
		if ((ret = AXUIElementCopyAttributeValue((AXUIElementRef)child, kAXRoleAttribute , (CFTypeRef*)&role)) != kAXErrorSuccess) {
            *error = AX_COPY_ATTR_ERROR(kAXRoleAttribute, ret);
            return NO;
        }
		
		if([role isEqualToString:NSAccessibilityDrawerRole]) {
			if (![AXWindowDriver getElement_:(AXUIElementRef)child origin:&(r.origin) error:&cause]) {
                *error = SICreateErrorWithCause(kWindowManagerFailureErrorCode, cause, @"AXError: Unable to position of a window drawer");
                return NO;                
            }
			if (![AXWindowDriver getElement_:(AXUIElementRef)child size:&(r.size) error:&cause]) {
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

+ (BOOL) setElement_:(AXUIElementRef)element size:(NSSize)size error:(NSError **)error {
    FMTAssertNotNil(element);
    FMTAssertNotNil(error);
    
    CFTypeRef sizeRef = (CFTypeRef)(AXValueCreate(kAXValueCGSizeType, (const void *)&size));
    AXError ret = 0;
    
    if ((ret = AXUIElementSetAttributeValue(element, kAXSizeAttribute, sizeRef)) != kAXErrorSuccess){
        *error = AX_SET_ATTR_ERROR(kAXSizeAttribute, ret);
        CFRelease(sizeRef);
        return NO;
    }		
    
    CFRelease(sizeRef);
    return YES;
}

@end

@implementation AXWindowDriver (WindowDelegate)

- (BOOL) setWindow_:(AXWindow *)window origin:(NSPoint)origin error:(NSError **)error {
	FMTAssertNotNil(window);
	FMTAssertNotNil(error);
    
    NSRect windowRect = [window windowRect_];
    NSRect windowRectWithDrawers = [window geometry];
    
    // readjust the drawers:
	// when moving the drawers are not taken into an account so need to manually
    // adjust the new position and size relative to the rect of drawers
    NSPoint newOrigin = origin;
	if (shouldUseDrawers_ && [window hasDrawers_]) {
        int dx = windowRect.origin.x - windowRectWithDrawers.origin.x;
        int dy = windowRectWithDrawers.origin.y - windowRect.origin.y;
        
		newOrigin.x += dx;
		newOrigin.y -= dy;
		
		FMTLogDebug(@"New window origin after drawers adjustment: %@", POINT_STR(newOrigin));
	}
    
	CFTypeRef newOriginRef = (CFTypeRef)(AXValueCreate(kAXValueCGPointType, (const void *)&newOrigin));
    AXError ret = 0;
	
    if ((ret = AXUIElementSetAttributeValue([window ref_], kAXPositionAttribute, newOriginRef)) != kAXErrorSuccess) {
		CFRelease(newOriginRef);
        *error = AX_SET_ATTR_ERROR(kAXPositionAttribute, ret);
        return NO;
	}
    
	CFRelease(newOriginRef);
    return YES;
}

- (BOOL) setWindow_:(AXWindow *)window size:(NSSize)size error:(NSError **)error {
	FMTAssertNotNil(window);
	FMTAssertNotNil(error);
	
    NSRect windowRect = [window windowRect_];
    NSRect windowRectWithDrawers = [window geometry];
    
    // readjust the drawers
	// when moving the drawers are not taken into an account so need to manually
    // adjust the new position and size relative to the rect of drawers
    NSSize newSize = size;    
	if (shouldUseDrawers_ && [window hasDrawers_]) {
        int dw = windowRectWithDrawers.size.width - windowRect.size.width;
        int dh = windowRectWithDrawers.size.height - windowRect.size.height;
        
		newSize.width -= dw;
		newSize.height -= dh;
		
		FMTLogDebug(@"Setting window geometry after drawers adjustements: %@", SIZE_STR(newSize));
	}
        
    // workaround for: http://lists.apple.com/archives/accessibility-dev/2011/Aug/msg00031.html
    NSError *cause = nil;
    NSSize lastTry;
    for (int i=1; i<=numberOfTries_; i++) {
        // try to resize
        FMTLogDebug(@"Resizing to: %@ (%d. attempt)", SIZE_STR(newSize), i);
        if (![AXWindowDriver setElement_:[window ref_] size:newSize error:&cause]) {
            *error = SICreateErrorWithCause(kAXWindowDriverErrorCode, 
                                            cause, 
                                            @"Unable to set window size to: %@", SIZE_STR(size));
            return NO;
        }

        // see what has happened
        NSSize actual;
        if (![AXWindowDriver getElement_:[window ref_] size:&actual error:&cause]) {
            *error = SICreateErrorWithCause(kAXWindowDriverErrorCode, 
                                            cause, 
                                            @"Unable to get window size to: %@", SIZE_STR(size));
            return NO;
        }        
        FMTLogDebug(@"Window resized to: %@ (%d. attempt)", SIZE_STR(actual), i);
        
        // compare to the expected
        if (NSEqualSizes(actual, newSize)) {
            break;
        } else if (i > 1 && (NSEqualSizes(actual, lastTry))) {
            // it seems that more attempts wont change anything
            FMTLogDebug(@"The %d attempt is the same as %d so no effect (likely a discretely sizing window)", i, i-1);
            break;
        }
        lastTry = actual;
    }
    
    return YES;
}

- (void) freeWindow_:(AXWindow *)window {
    FMTAssertNotNil(window);
    
    CFRelease([window ref_]);
}

@end
