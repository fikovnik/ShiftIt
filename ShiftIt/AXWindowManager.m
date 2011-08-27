//
//  AXWindowManager.m
//  ShiftIt
//
//  Created by Filip Krikava on 8/27/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AXWindowManager.h"
#import "ShiftIt.h"
#import "FMTDefines.h"

@interface AXWindowManager(Private)
+ (BOOL) isAttributeSettable_:(CFStringRef)attributeName element:(AXUIElementRef)element;
@end

@implementation AXWindowManager

SINGLETON_BOILERPLATE(AXWindowManager, sharedAXWindowManager);

- (id)init {
	if(![super init]){
		return nil;
	}
    
    return self;
}

- (BOOL) getFocusedWindow:(AXUIElementRef *)windowRef error:(NSError **)error {  
    FMTAssertNotNil(windowRef);
    
    AXUIElementRef systemElementRef = AXUIElementCreateSystemWide();
	// here is the assert for purpose because the app should not have gone 
	// that far in execution if the AX api is not available
	FMTAssertNotNil(systemElementRef);
    
    //get the focused application
    AXUIElementRef focusedAppRef = nil;
    AXError ret = 0;
    
    if ((ret = AXUIElementCopyAttributeValue(systemElementRef,
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

- (void) freeWindow:(AXUIElementRef)windowRef {
    FMTAssertNotNil(windowRef);
    
    CFRelease(windowRef);
}

- (BOOL) setPosition:(NSPoint)position window:(AXUIElementRef)windowRef error:(NSError **)error {
	FMTAssertNotNil(windowRef);
    
	CFTypeRef positionRef = (CFTypeRef)(AXValueCreate(kAXValueCGPointType, (const void *)&position));
    AXError ret = 0;
	
    if ((ret = AXUIElementSetAttributeValue(windowRef, kAXPositionAttribute, positionRef)) != kAXErrorSuccess) {
		CFRelease(positionRef);
        *error = SICreateError(FMTStr(@"AXError: kAXPositionAttribute set failed: %d", ret), kAXFailureErrorCode);
        return NO;
	}
    
	CFRelease(positionRef);
    return YES;
}

- (BOOL) setSize:(NSSize)size window:(AXUIElementRef)windowRef error:(NSError **)error {
	FMTAssertNotNil(windowRef);
	
	CFTypeRef sizeRef = (CFTypeRef)(AXValueCreate(kAXValueCGSizeType, (const void *)&size));
    AXError ret = 0;
	
    if ((ret = AXUIElementSetAttributeValue(windowRef, kAXSizeAttribute, sizeRef)) != kAXErrorSuccess){
        *error = SICreateError(FMTStr(@"AXError: kAXSizeAttribute set failed: %d", ret), kAXFailureErrorCode);
		CFRelease(sizeRef);
        return NO;
	}		
    
	CFRelease(sizeRef);
    return YES;
}

- (BOOL) getGeometry:(NSRect *)rect window:(AXUIElementRef)windowRef error:(NSError **)error {
	FMTAssertNotNil(windowRef);
	FMTAssertNotNil(rect);
	
	if (![self getPosition:&(rect->origin) element:windowRef error:error]) {
		return NO;
	}
    
	if (![self getSize:&(rect->size) element:windowRef error:error]) {
		return NO;
	}
    
    return YES;
}

- (BOOL) getDrawersGeometry:(NSRect *)rect window:(AXUIElementRef)windowRef error:(NSError **)error {
	FMTAssertNotNil(windowRef);
	FMTAssertNotNil(rect);
    
	NSArray *children = nil;
    AXError ret = 0;
    
    // by defult there are none
    *rect = NSMakeRect(0, 0, 0, 0);
    
	if ((ret = AXUIElementCopyAttributeValue(windowRef, kAXChildrenAttribute, (CFTypeRef*)&children)) != kAXErrorSuccess) {
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
			if (![self getPosition:&(r.origin) element:(AXUIElementRef)child error:&cause]) {
                *error = SICreateErrorWithCause(@"AXError: Unable to position of a window drawer", kUnableToGetWindowDrawersErrorCode, cause);
                return NO;                
            }
			if (![self getSize:&(r.size) element:(AXUIElementRef)child error:&cause]) {
                *error = SICreateErrorWithCause(@"AXError: Unable to size of a window drawer", kUnableToGetWindowDrawersErrorCode, cause);
                return NO;                                
            }
			
			if (first) {
				*rect = r;
				first = NO;
			} else {
				*rect = NSUnionRect(*rect, r);
			}
		}
		
		CFRelease((CFTypeRef) role);
	}
	
	[children release];
	return YES;
}

- (BOOL) getFullScreenMode:(BOOL *)fullScreen window:(AXUIElementRef)windowRef error:(NSError **)error {
    FMTAssertNotNil(windowRef);
    FMTAssertNotNil(fullScreen);
	
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


- (BOOL) getPosition:(NSPoint *)position element:(AXUIElementRef)element error:(NSError **)error {
	FMTAssertNotNil(element);
	FMTAssertNotNil(position);
    
	CFTypeRef positionRef;
    AXError ret = 0;
	
	if ((ret = AXUIElementCopyAttributeValue(element,kAXPositionAttribute, &positionRef)) != kAXErrorSuccess) {
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

- (BOOL) getSize:(NSSize *)size element:(AXUIElementRef)element error:(NSError **)error {
	FMTAssertNotNil(element);
	FMTAssertNotNil(size);
    
	CFTypeRef sizeRef;
    AXError ret = 0;
    
	if ((ret = AXUIElementCopyAttributeValue(element, kAXSizeAttribute, &sizeRef)) != kAXErrorSuccess) {
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

- (BOOL) isWindowResizeable:(AXUIElementRef)window {
    return [AXWindowManager isAttributeSettable_:kAXSizeAttribute element:window];
}

- (BOOL) isWindowMoveable:(AXUIElementRef)window {
    return [AXWindowManager isAttributeSettable_:kAXPositionAttribute element:window];
}

+ (BOOL) isAttributeSettable_:(CFStringRef)attributeName element:(AXUIElementRef)element {
    Boolean isSettable = false;
    
    AXUIElementIsAttributeSettable(element, (CFStringRef)attributeName, &isSettable);
    
    return isSettable == true ? YES : NO;
}


@end
