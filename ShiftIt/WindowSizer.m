//
//  WindowSizer.m
//  ShiftIt
//
//  Created by Aravindkumar Rajendiran on 10-02-13.
//  Copyright 2010 Grapewave. All rights reserved.
//

#import "WindowSizer.h"


@implementation WindowSizer

-(void)getWindowParameters{
	NSScreen * screen = [NSScreen mainScreen];
	_fullScreenSize = screen.frame.size;
	_startPosition = screen.visibleFrame;
	_screenRectSize = screen.visibleFrame.size;
	AXUIElementCopyAttributeValue(_systemWideElement,(CFStringRef)kAXFocusedApplicationAttribute,(CFTypeRef*)&_focusedApp);
	if(AXUIElementCopyAttributeValue((AXUIElementRef)_focusedApp,(CFStringRef)NSAccessibilityFocusedWindowAttribute,(CFTypeRef*)&_focusedWindow) == kAXErrorSuccess) {
		if(CFGetTypeID(_focusedWindow) == AXUIElementGetTypeID()) {
			if(AXUIElementCopyAttributeValue((AXUIElementRef)_focusedWindow,(CFStringRef)NSAccessibilityPositionAttribute,(CFTypeRef*)&_position) != kAXErrorSuccess) {
				NSLog(@"Can't Retrieve Window Position");
			}
			if(AXUIElementCopyAttributeValue((AXUIElementRef)_focusedWindow,(CFStringRef)NSAccessibilitySizeAttribute,(CFTypeRef*)&_size) != kAXErrorSuccess) {
				NSLog(@"Can't Retrieve Window Size");
			}
		}
	}else {
		NSLog(@"Problem with App");
	}
	
}

-(IBAction)shiftToLeftHalf:(id)sender{
	[self getWindowParameters];
	if(AXValueGetType(_position) == kAXValueCGPointType) {
		NSPoint thePoint;
		NSSize theSize;
		thePoint.x = 0;
		thePoint.y = 0;
		_position = (CFTypeRef)(AXValueCreate(kAXValueCGPointType, (const void *)&thePoint));
		
		if(AXValueGetType(_size) == kAXValueCGSizeType) {
			theSize.width = ((_screenRectSize.width)/2);
			theSize.height = _fullScreenSize.height;
			_size = (CFTypeRef)(AXValueCreate(kAXValueCGSizeType, (const void *)&theSize));					
		}
		if(AXUIElementSetAttributeValue((AXUIElementRef)_focusedWindow,(CFStringRef)NSAccessibilityPositionAttribute,(CFTypeRef*)_position) != kAXErrorSuccess){
			NSLog(@"Position cannot be changed");
		}
		if(AXUIElementSetAttributeValue((AXUIElementRef)_focusedWindow,(CFStringRef)NSAccessibilitySizeAttribute,(CFTypeRef*)_size) != kAXErrorSuccess){
			NSLog(@"Size cannot be modified");
		}
	}
	_focusedApp = NULL;
	_focusedWindow = NULL;
	_position = NULL;
	_size = NULL;
}

-(IBAction)shiftToRightHalf:(id)sender{
	[self getWindowParameters];
	if(AXValueGetType(_position) == kAXValueCGPointType) {
		NSPoint thePoint;
		NSSize theSize;
		thePoint.x = (_screenRectSize.width/2);
		thePoint.y = 0;
		_position = (CFTypeRef)(AXValueCreate(kAXValueCGPointType, (const void *)&thePoint));
		
		if(AXValueGetType(_size) == kAXValueCGSizeType) {
			theSize.width = (_screenRectSize.width/2);
			theSize.height = _fullScreenSize.height;
			_size = (CFTypeRef)(AXValueCreate(kAXValueCGSizeType, (const void *)&theSize));					
		}
		if(AXUIElementSetAttributeValue((AXUIElementRef)_focusedWindow,(CFStringRef)NSAccessibilityPositionAttribute,(CFTypeRef*)_position) != kAXErrorSuccess){
			NSLog(@"Position cannot be changed");
		}
		if(AXUIElementSetAttributeValue((AXUIElementRef)_focusedWindow,(CFStringRef)NSAccessibilitySizeAttribute,(CFTypeRef*)_size) != kAXErrorSuccess){
			NSLog(@"Size cannot be modified");
		}
	}
	_focusedApp = NULL;
	_focusedWindow = NULL;
	_position = NULL;
	_size = NULL;
	
}

-(IBAction)shiftToTopHalf:(id)sender{
	[self getWindowParameters];
	if(AXValueGetType(_position) == kAXValueCGPointType) {
		NSPoint thePoint;
		NSSize theSize;
		thePoint.x = 0;
		thePoint.y = 0;
		_position = (CFTypeRef)(AXValueCreate(kAXValueCGPointType, (const void *)&thePoint));
		
		if(AXValueGetType(_size) == kAXValueCGSizeType) {
			theSize.width = _screenRectSize.width;
			theSize.height = (_fullScreenSize.height/2);
			_size = (CFTypeRef)(AXValueCreate(kAXValueCGSizeType, (const void *)&theSize));					
		}
		if(AXUIElementSetAttributeValue((AXUIElementRef)_focusedWindow,(CFStringRef)NSAccessibilityPositionAttribute,(CFTypeRef*)_position) != kAXErrorSuccess){
			NSLog(@"Position cannot be changed");
		}
		if(AXUIElementSetAttributeValue((AXUIElementRef)_focusedWindow,(CFStringRef)NSAccessibilitySizeAttribute,(CFTypeRef*)_size) != kAXErrorSuccess){
			NSLog(@"Size cannot be modified");
		}
	}
	_focusedApp = NULL;
	_focusedWindow = NULL;
	_position = NULL;
	_size = NULL;
}

-(IBAction)shiftToBottomHalf:(id)sender{
	[self getWindowParameters];
	if(AXValueGetType(_position) == kAXValueCGPointType) {
		NSPoint thePoint;
		NSSize theSize;
		thePoint.x = 0;
		thePoint.y = ((_fullScreenSize.height/2)-(_startPosition.origin.y));
		_position = (CFTypeRef)(AXValueCreate(kAXValueCGPointType, (const void *)&thePoint));
		
		if(AXValueGetType(_size) == kAXValueCGSizeType) {
			theSize.width = _screenRectSize.width;
			theSize.height = (_fullScreenSize.height/2);
			_size = (CFTypeRef)(AXValueCreate(kAXValueCGSizeType, (const void *)&theSize));					
		}
		if(AXUIElementSetAttributeValue((AXUIElementRef)_focusedWindow,(CFStringRef)NSAccessibilityPositionAttribute,(CFTypeRef*)_position) != kAXErrorSuccess){
			NSLog(@"Position cannot be changed");
		}
		if(AXUIElementSetAttributeValue((AXUIElementRef)_focusedWindow,(CFStringRef)NSAccessibilitySizeAttribute,(CFTypeRef*)_size) != kAXErrorSuccess){
			NSLog(@"Size cannot be modified");
		}
	}
	_focusedApp = NULL;
	_focusedWindow = NULL;
	_position = NULL;
	_size = NULL;
}

-(IBAction)shiftToTopLeft:(id)sender{
	[self getWindowParameters];
	if(AXValueGetType(_position) == kAXValueCGPointType) {
		NSPoint thePoint;
		NSSize theSize;
		thePoint.x = 0;
		thePoint.y = 0;
		_position = (CFTypeRef)(AXValueCreate(kAXValueCGPointType, (const void *)&thePoint));
		
		if(AXValueGetType(_size) == kAXValueCGSizeType) {
			theSize.width = (_screenRectSize.width/2);
			theSize.height = (_fullScreenSize.height/2);
			_size = (CFTypeRef)(AXValueCreate(kAXValueCGSizeType, (const void *)&theSize));					
		}
		if(AXUIElementSetAttributeValue((AXUIElementRef)_focusedWindow,(CFStringRef)NSAccessibilityPositionAttribute,(CFTypeRef*)_position) != kAXErrorSuccess){
			NSLog(@"Position cannot be changed");
		}
		if(AXUIElementSetAttributeValue((AXUIElementRef)_focusedWindow,(CFStringRef)NSAccessibilitySizeAttribute,(CFTypeRef*)_size) != kAXErrorSuccess){
			NSLog(@"Size cannot be modified");
		}
	}
	_focusedApp = NULL;
	_focusedWindow = NULL;
	_position = NULL;
	_size = NULL;
}

-(IBAction)shiftToTopRight:(id)sender{
	[self getWindowParameters];
	if(AXValueGetType(_position) == kAXValueCGPointType) {
		NSPoint thePoint;
		NSSize theSize;
		thePoint.x = (_screenRectSize.width/2);
		thePoint.y = 0;
		_position = (CFTypeRef)(AXValueCreate(kAXValueCGPointType, (const void *)&thePoint));
		
		if(AXValueGetType(_size) == kAXValueCGSizeType) {
			theSize.width = (_screenRectSize.width/2);
			theSize.height = (_fullScreenSize.height/2);
			_size = (CFTypeRef)(AXValueCreate(kAXValueCGSizeType, (const void *)&theSize));					
		}
		if(AXUIElementSetAttributeValue((AXUIElementRef)_focusedWindow,(CFStringRef)NSAccessibilityPositionAttribute,(CFTypeRef*)_position) != kAXErrorSuccess){
			NSLog(@"Position cannot be changed");
		}
		if(AXUIElementSetAttributeValue((AXUIElementRef)_focusedWindow,(CFStringRef)NSAccessibilitySizeAttribute,(CFTypeRef*)_size) != kAXErrorSuccess){
			NSLog(@"Size cannot be modified");
		}
	}
	_focusedApp = NULL;
	_focusedWindow = NULL;
	_position = NULL;
	_size = NULL;
}

-(IBAction)shiftToBottomLeft:(id)sender{
	[self getWindowParameters];
	if(AXValueGetType(_position) == kAXValueCGPointType) {
		NSPoint thePoint;
		NSSize theSize;
		thePoint.x = 0;
		thePoint.y = ((_fullScreenSize.height/2)-(_startPosition.origin.y));
		_position = (CFTypeRef)(AXValueCreate(kAXValueCGPointType, (const void *)&thePoint));
		
		if(AXValueGetType(_size) == kAXValueCGSizeType) {
			theSize.width = (_screenRectSize.width/2);
			theSize.height = ((_fullScreenSize.height/2));
			_size = (CFTypeRef)(AXValueCreate(kAXValueCGSizeType, (const void *)&theSize));					
		}
		if(AXUIElementSetAttributeValue((AXUIElementRef)_focusedWindow,(CFStringRef)NSAccessibilityPositionAttribute,(CFTypeRef*)_position) != kAXErrorSuccess){
			NSLog(@"Position cannot be changed");
		}
		if(AXUIElementSetAttributeValue((AXUIElementRef)_focusedWindow,(CFStringRef)NSAccessibilitySizeAttribute,(CFTypeRef*)_size) != kAXErrorSuccess){
			NSLog(@"Size cannot be modified");
		}
	}
	_focusedApp = NULL;
	_focusedWindow = NULL;
	_position = NULL;
	_size = NULL;
}

-(IBAction)shiftToBottomRight:(id)sender{
	[self getWindowParameters];
	if(AXValueGetType(_position) == kAXValueCGPointType) {
		NSPoint thePoint;
		NSSize theSize;
		thePoint.x = (_screenRectSize.width/2);
		thePoint.y = ((_fullScreenSize.height/2)-(_startPosition.origin.y));
		_position = (CFTypeRef)(AXValueCreate(kAXValueCGPointType, (const void *)&thePoint));
		
		if(AXValueGetType(_size) == kAXValueCGSizeType) {
			theSize.width = (_screenRectSize.width/2);
			theSize.height = ((_fullScreenSize.height/2));
			_size = (CFTypeRef)(AXValueCreate(kAXValueCGSizeType, (const void *)&theSize));					
		}
		if(AXUIElementSetAttributeValue((AXUIElementRef)_focusedWindow,(CFStringRef)NSAccessibilityPositionAttribute,(CFTypeRef*)_position) != kAXErrorSuccess){
			NSLog(@"Position cannot be changed");
		}
		if(AXUIElementSetAttributeValue((AXUIElementRef)_focusedWindow,(CFStringRef)NSAccessibilitySizeAttribute,(CFTypeRef*)_size) != kAXErrorSuccess){
			NSLog(@"Size cannot be modified");
		}
	}
	_focusedApp = NULL;
	_focusedWindow = NULL;
	_position = NULL;
	_size = NULL;
}

-(IBAction)shiftToCenter:(id)sender{
	[self getWindowParameters];
	if(AXValueGetType(_position) == kAXValueCGPointType) {
		NSPoint thePoint;
		NSSize originalSize;
		AXValueGetValue((AXValueRef)_size, kAXValueCGSizeType, &originalSize);
		NSLog(@"%d, %d",originalSize.width,originalSize.height);
		if(AXValueGetType(_size) == kAXValueCGSizeType) {
			thePoint.x = ((_screenRectSize.width/2) - (originalSize.width/2));
			thePoint.y = ((_screenRectSize.height/2) - (originalSize.height/2));
			NSLog(@"%d, %d",thePoint.x,thePoint.y);
			_position = (CFTypeRef)(AXValueCreate(kAXValueCGPointType, (const void *)&thePoint));
		}
		if(AXUIElementSetAttributeValue((AXUIElementRef)_focusedWindow,(CFStringRef)NSAccessibilityPositionAttribute,(CFTypeRef*)_position) != kAXErrorSuccess){
			NSLog(@"Position cannot be changed");
		}
	}
	_focusedApp = NULL;
	_focusedWindow = NULL;
	_position = NULL;
	_size = NULL;	
}

-(IBAction)fullScreen:(id)sender{
	[self getWindowParameters];
	if(AXValueGetType(_position) == kAXValueCGPointType) {
		NSPoint thePoint;
		NSSize theSize;
		thePoint.x = 0;
		thePoint.y = 0;
		_position = (CFTypeRef)(AXValueCreate(kAXValueCGPointType, (const void *)&thePoint));
		
		if(AXValueGetType(_size) == kAXValueCGSizeType) {
			theSize.width = _screenRectSize.width;
			theSize.height = _screenRectSize.height;
			_size = (CFTypeRef)(AXValueCreate(kAXValueCGSizeType, (const void *)&theSize));					
		}
		if(AXUIElementSetAttributeValue((AXUIElementRef)_focusedWindow,(CFStringRef)NSAccessibilityPositionAttribute,(CFTypeRef*)_position) != kAXErrorSuccess){
			NSLog(@"Position cannot be changed");
		}
		if(AXUIElementSetAttributeValue((AXUIElementRef)_focusedWindow,(CFStringRef)NSAccessibilitySizeAttribute,(CFTypeRef*)_size) != kAXErrorSuccess){
			NSLog(@"Size cannot be modified");
		}
	}
	_focusedApp = NULL;
	_focusedWindow = NULL;
	_position = NULL;
	_size = NULL;
}

-(WindowSizer *)init{
	if(self = [super init]){;
		_systemWideElement = AXUIElementCreateSystemWide();
	}
	return self;
}

@end
