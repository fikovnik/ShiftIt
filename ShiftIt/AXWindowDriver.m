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

@interface AXWindowDriver(Private)

+ (BOOL) canAttribute_:(CFStringRef)attributeName ofElement:(AXUIElementRef)element change:(BOOL *)changeable error:(NSError **)error;

+ (BOOL) pressButton_:(CFStringRef)buttonName ofElement:(AXUIElementRef)element error:(NSError **)error;

- (BOOL) getElement_:(SIWindowRef)element position:(NSPoint *)position error:(NSError **)error;

- (BOOL) getElement_:(SIWindowRef)element size:(NSSize *)size error:(NSError **)error;

@end

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
                                             (CFStringRef) kAXFocusedApplicationAttribute,
                                             (CFTypeRef *) &focusedAppRef)) != kAXErrorSuccess) {
        *error = SICreateError(FMTStr(@"AXError: kAXFocusedApplicationAttribute copy failed: %d", ret), kAXFailureErrorCode);
        return NO;
    }    
    FMTAssertNotNil(focusedAppRef);
    
    //get the focused window
    if ((ret = AXUIElementCopyAttributeValue((AXUIElementRef)focusedAppRef,
                                             (CFStringRef)kAXFocusedWindowAttribute,
                                             (CFTypeRef*)windowRef)) != kAXErrorSuccess) {
        
        *error = SICreateError(FMTStr(@"AXError: kAXFocusedWindowAttribute copy failed: %d", ret), kAXFailureErrorCode);
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
        *error = SICreateError(FMTStr(@"AXError: kAXPositionAttribute set failed: %d", ret), kAXFailureErrorCode);
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
        *error = SICreateError(FMTStr(@"AXError: kAXSizeAttribute set failed: %d", ret), kAXFailureErrorCode);
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
	
	if (![self getElement_:windowRef position:&(geometry->origin) error:error]) {
		return NO;
	}
    
	if (![self getElement_:windowRef size:&(geometry->size) error:error]) {
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
    
    // TODO: we should check if there are actually drawers
	if ((ret = AXUIElementCopyAttributeValue((AXUIElementRef)windowRef, kAXChildrenAttribute, (CFTypeRef*)&children)) != kAXErrorSuccess) {
        *error = SICreateError(FMTStr(@"AXError: kAXChildrenAttribute copy failed: %d", ret), kAXFailureErrorCode);
		return NO;
	}
    
	NSRect r; // for the loop
	
	BOOL first = YES;
    NSError *cause = nil;
	for (id child in children) {
		NSString *role = nil;
		
		if ((ret = AXUIElementCopyAttributeValue((AXUIElementRef)child, kAXRoleAttribute , (CFTypeRef*)&role)) != kAXErrorSuccess) {
            *error = SICreateError(FMTStr(@"AXError: kAXRoleAttribute copy failed: %d", ret), kAXFailureErrorCode);
            return NO;
        }
		
		if([role isEqualToString:NSAccessibilityDrawerRole]) {
			if (![self getElement_:(SIWindowRef)child position:&(r.origin) error:&cause]) {
                *error = SICreateErrorWithCause(@"AXError: Unable to position of a window drawer", kWindowManagerFailureErrorCode, cause);
                return NO;                
            }
			if (![self getElement_:(SIWindowRef)child size:&(r.size) error:&cause]) {
                *error = SICreateErrorWithCause(@"AXError: Unable to size of a window drawer", kWindowManagerFailureErrorCode, cause);
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
        
        *error = SICreateError(FMTStr(@"AXError: kAXFullScreenAttribute copy failed: %d", ret), kAXFailureErrorCode);
        return NO;
    }
    
    *fullScreen = fullScreenRef == kCFBooleanTrue ? YES : NO;
	CFRelease(fullScreenRef);
	
	return YES;
}


- (BOOL) getElement_:(SIWindowRef)element position:(NSPoint *)position error:(NSError **)error {
	FMTAssertNotNil(element);
	FMTAssertNotNil(position);
	FMTAssertNotNil(error);
    
	CFTypeRef positionRef;
    AXError ret = 0;
	
	if ((ret = AXUIElementCopyAttributeValue((AXUIElementRef)element,kAXPositionAttribute, &positionRef)) != kAXErrorSuccess) {
        *error = SICreateError(FMTStr(@"AXError: kAXPositionAttribute copy failed: %d", ret), kAXFailureErrorCode);
		return NO;
	}
	
	FMTAssertNotNil(positionRef);
    
	if(AXValueGetType(positionRef) == kAXValueCGPointType) {
		AXValueGetValue(positionRef, kAXValueCGPointType, position);
	} else {
		CFRelease(positionRef);
        *error = SICreateError(FMTStr(@"AXError: invalid value type. Expected: kAXValueCGPointType, got: %d", AXValueGetType(positionRef)), kAXFailureErrorCode);
		return NO;
	}
	
	CFRelease(positionRef);
	return YES;
}

- (BOOL) getElement_:(SIWindowRef)element size:(NSSize *)size error:(NSError **)error {
	FMTAssertNotNil(element);
	FMTAssertNotNil(size);
	FMTAssertNotNil(error);
    
	CFTypeRef sizeRef;
    AXError ret = 0;
    
	if ((ret = AXUIElementCopyAttributeValue((AXUIElementRef)element, kAXSizeAttribute, &sizeRef)) != kAXErrorSuccess) {
        *error = SICreateError(FMTStr(@"AXError: kAXSizeAttribute copy failed: %d", ret), kAXFailureErrorCode);
		return NO;
	}
	
	FMTAssertNotNil(sizeRef);
    
	if(AXValueGetType(sizeRef) == kAXValueCGSizeType) {
		AXValueGetValue(sizeRef, kAXValueCGSizeType, size);
	} else {
        CFRelease(sizeRef);
        *error = SICreateError(FMTStr(@"AXError: invalid value type. Expected: kAXValueCGSizeType, got: %d", AXValueGetType(sizeRef)), kAXFailureErrorCode);
		return NO;
	}
	
	CFRelease(sizeRef);
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
        *error = SICreateError(FMTStr(@"AXError: %@ copy failed: %d", (NSString *)buttonName, ret), kAXFailureErrorCode);
        return NO;
    }
    
    FMTAssertNotNil(button);
    
    if ((ret = AXUIElementPerformAction(button, kAXPressAction)) != kAXErrorSuccess) {
        CFRelease(button);
        *error = SICreateError(FMTStr(@"AXError: perform action kAXPressAction failed: %d", ret), kAXFailureErrorCode);
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
        *error = SICreateError(FMTStr(@"AXError: Unable to check whether attribute: %@ is settable", (NSString *)attributeName), kAXFailureErrorCode);
        return NO;
    }
    
    *changeable = isSettable == true ? YES : NO;
    
    return YES;
}


@end
