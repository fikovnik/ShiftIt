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

#define AX_COPY_ATTR_ERROR(attr, ret) SICreateError(kAXFailureErrorCode, @"AXUICopyAttributeValue failure: attribute: (attr) error: (ret)")
#define AX_SET_ATTR_ERROR(attr, ret) SICreateError(kAXFailureErrorCode, @"AXUISetAttributeValue failure: attribute: (attr) error: (ret)")
#define AX_PERF_ACTION_ERROR(action, ret) SICreateError(kAXFailureErrorCode, @"AXUIPerformAction failure: action: (action) error: (ret)")
#define AX_IS_ATTR_SETTABLE_ERROR(attr, ret) SICreateError(kAXFailureErrorCode, @"AXUIIsAttributeSettable failure: action: (attr) error: (ret)")

#define AX_VALUE_TYPE_ERROR(expected, actual) SICreateError(kAXFailureErrorCode, @"AXTypeError: expected: (expected) got: (actual)")

#pragma mark Utility Functions

@interface AXWindowDriver(Private)

+ (BOOL) canAttribute_:(CFStringRef)attributeName ofElement:(AXUIElementRef)element change:(BOOL *)changeable error:(NSError **)error;

+ (BOOL) pressButton_:(CFStringRef)buttonName ofElement:(AXUIElementRef)element error:(NSError **)error;

+ (BOOL) getElement_:(AXUIElementRef)element position:(NSPoint *)position error:(NSError **)error;

+ (BOOL) getElement_:(AXUIElementRef)element size:(NSSize *)size error:(NSError **)error;

@end

#pragma mark AX Window Driver Implementation

@implementation AXWindowDriver

- (id)init {
	if(![super init]){
		return nil;
	}
    
    systemElementRef_ = AXUIElementCreateSystemWide();
    // here is the assert for purpose because the app should not have gone 
	// that far in execution if the AX api is not available
	FMTAssertNotNil(systemElementRef_);
    
    return self;
}

- (void) dealloc {
    CFRelease(systemElementRef_);
}

- (BOOL) getFocusedWindow:(SIWindowRef *)windowRef error:(NSError **)error {  
    FMTAssertNotNil(windowRef);
	FMTAssertNotNil(error);
    
    //get the focused application
    AXUIElementRef focusedAppRef = nil;
    AXError ret = 0;
    
    if ((ret = AXUIElementCopyAttributeValue(systemElementRef_,
                                             kAXFocusedApplicationAttribute,
                                             (CFTypeRef *) &focusedAppRef)) != kAXErrorSuccess) {
        *error = AX_COPY_ATTR_ERROR(kAXFocusedApplicationAttribute, ret);
        return NO;
    }    
    
    FMTAssertNotNil(focusedAppRef);
    
    //get the focused window
    if ((ret = AXUIElementCopyAttributeValue(focusedAppRef,
                                             kAXFocusedWindowAttribute,
                                             (CFTypeRef*) windowRef)) != kAXErrorSuccess) {
        
        *error = AX_COPY_ATTR_ERROR(kAXFocusedWindowAttribute, ret);
        CFRelease(focusedAppRef);
        return NO;
    }
    
    return YES;
}

- (void) freeWindow:(SIWindowRef)windowRef {
    FMTAssertNotNil(windowRef);
    
    CFRelease((AXUIElementRef)windowRef);
}

- (BOOL) setWindow:(SIWindowRef)windowRef position:(NSPoint)position error:(NSError **)error {
	FMTAssertNotNil(windowRef);
	FMTAssertNotNil(error);
    
	CFTypeRef positionRef = (CFTypeRef)(AXValueCreate(kAXValueCGPointType, (const void *)&position));
    AXError ret = 0;
	
    if ((ret = AXUIElementSetAttributeValue((AXUIElementRef)windowRef, kAXPositionAttribute, positionRef)) != kAXErrorSuccess) {
		CFRelease(positionRef);
        *error = AX_SET_ATTR_ERROR(kAXPositionAttribute, ret);
        return NO;
	}
    
	CFRelease(positionRef);
    return YES;
}

- (BOOL) setWindow:(SIWindowRef)windowRef size:(NSSize)size error:(NSError **)error {
	FMTAssertNotNil(windowRef);
	FMTAssertNotNil(error);
	
	CFTypeRef sizeRef = (CFTypeRef)(AXValueCreate(kAXValueCGSizeType, (const void *)&size));
    AXError ret = 0;
	
    if ((ret = AXUIElementSetAttributeValue((AXUIElementRef)windowRef, kAXSizeAttribute, sizeRef)) != kAXErrorSuccess){
        *error = AX_SET_ATTR_ERROR(kAXSizeAttribute, ret);
		CFRelease(sizeRef);
        return NO;
	}		
    
	CFRelease(sizeRef);
    return YES;
}

- (BOOL) getWindow:(SIWindowRef)windowRef geometry:(NSRect *)geometry error:(NSError **)error {
	FMTAssertNotNil(windowRef);
	FMTAssertNotNil(geometry);
	FMTAssertNotNil(error);
	
	if (![AXWindowDriver getElement_:(AXUIElementRef)windowRef position:&(geometry->origin) error:error]) {
		return NO;
	}
    
	if (![AXWindowDriver getElement_:(AXUIElementRef)windowRef size:&(geometry->size) error:error]) {
		return NO;
	}
    
    return YES;
}

- (BOOL) getWindow:(SIWindowRef)windowRef drawersGeometry:(NSRect *)geometry error:(NSError **)error {
	FMTAssertNotNil(windowRef);
	FMTAssertNotNil(geometry);
	FMTAssertNotNil(error);
    
	NSArray *children = nil;
    AXError ret = 0;
    
    // by defult there are none
    *geometry = NSMakeRect(0, 0, 0, 0);
    
	if ((ret = AXUIElementCopyAttributeValue((AXUIElementRef)windowRef, kAXChildrenAttribute, (CFTypeRef *)&children)) != kAXErrorSuccess) {
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
			if (![AXWindowDriver getElement_:(AXUIElementRef)child position:&(r.origin) error:&cause]) {
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

- (BOOL) isWindow:(SIWindowRef)windowRef inFullScreen:(BOOL *)fullScreen error:(NSError **)error {
    FMTAssertNotNil(windowRef);
    FMTAssertNotNil(fullScreen);
	FMTAssertNotNil(error);
	
    CFBooleanRef fullScreenRef;
    AXError ret = 0;
    
    if ((ret = AXUIElementCopyAttributeValue((AXUIElementRef)windowRef,
                                             (CFStringRef) kAXFullScreenAttribute,
                                             (CFTypeRef *) &fullScreenRef)) != kAXErrorSuccess) {
        
        *error = AX_COPY_ATTR_ERROR(kAXFullScreenAttribute, ret);
        return NO;
    }
    
    *fullScreen = fullScreenRef == kCFBooleanTrue ? YES : NO;
	CFRelease(fullScreenRef);
	
	return YES;
}


- (BOOL) canWindow:(SIWindowRef)window resize:(BOOL *)resizeable error:(NSError **)error {    // args asserted in the nested call
    // args asserted in the nested call
    BOOL changeable;
    
    if (![AXWindowDriver canAttribute_:kAXSizeAttribute ofElement:window change:&changeable error:error]) {
		return NO;
    }
    
    return YES;
}

- (BOOL) canWindow:(SIWindowRef)window move:(BOOL *)moveable error:(NSError **)error {
    // args asserted in the nested call
    BOOL changeable;
    
    if (![AXWindowDriver canAttribute_:kAXPositionAttribute ofElement:window change:&changeable error:error]) {
		return NO;
    }
    
    return YES;
}

- (BOOL) toggleZoomOnWindow:(SIWindowRef)window error:(NSError **)error {    
    // args asserted in the nested call
    return [AXWindowDriver pressButton_:kAXZoomButtonAttribute ofElement:window error:error];
}

- (BOOL) toggleFullScreenOnWindow:(SIWindowRef)window error:(NSError **)error {
    // args asserted in the nested call
    return [AXWindowDriver pressButton_:kAXFullScreenButtonAttribute ofElement:window error:error];
}

@end

#pragma mark Utility Functions Implementation

@implementation AXWindowDriver (Private)

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
    
    if (AXUIElementIsAttributeSettable(element, (CFStringRef)attributeName, &isSettable) != kAXErrorSuccess) {
        *error = AX_IS_ATTR_SETTABLE_ERROR((NSString *)attributeName, ret);
        return NO;
    }
    
    *changeable = isSettable == true ? YES : NO;
    
    return YES;
}

+ (BOOL) getElement_:(AXUIElementRef)element position:(NSPoint *)position error:(NSError **)error {
	FMTAssertNotNil(element);
	FMTAssertNotNil(position);
	FMTAssertNotNil(error);
    
	CFTypeRef positionRef;
    AXError ret = 0;
	
	if ((ret = AXUIElementCopyAttributeValue(element,kAXPositionAttribute, &positionRef)) != kAXErrorSuccess) {
        *error = AX_COPY_ATTR_ERROR(kAXPositionAttribute, ret);
		return NO;
	}
	
	FMTAssertNotNil(positionRef);
    
	if(AXValueGetType(positionRef) == kAXValueCGPointType) {
		AXValueGetValue(positionRef, kAXValueCGPointType, position);
	} else {
		CFRelease(positionRef);
        *error = AX_VALUE_TYPE_ERROR(kAXValueCGPointType, AXValueGetType(positionRef));
		return NO;
	}
	
	CFRelease(positionRef);
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


@end
