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

#import "WindowSizer.h"
#import <Carbon/Carbon.h>

@implementation WindowSizer

-(void)chooseScreen{
    CGDirectDisplayID tempId[2];
    CGDisplayCount tempCount;
    CGError error = CGGetDisplaysWithRect(CGRectMake(windowPosition_.x, windowPosition_.y, windowSize_.width, windowSize_.height), 2, tempId, &tempCount);
    if(error == kCGErrorSuccess){
        CGRect screenBounds = CGDisplayBounds(tempId[0]);
        if(tempCount == 1){
            screenPosition_.x = screenBounds.origin.x;
            screenPosition_.y = screenBounds.origin.y;
            screenSize_.width = screenBounds.size.width;
            screenSize_.height = screenBounds.size.height;
        }else if (tempCount == 2) {
            CGRect screenBounds1 = CGDisplayBounds(tempId[1]);
            int screenChosen = 0;
            int delta = abs(screenBounds.origin.x - (windowPosition_.x+windowSize_.width));
            int delta2 = 0;
            if(delta > screenBounds.size.width){
                delta = abs(windowPosition_.x - (screenBounds.origin.x+screenBounds.size.width));
                delta2 = abs(windowPosition_.x+windowSize_.width - screenBounds1.origin.x);
            }else {
                delta2 = abs(windowPosition_.x - (screenBounds1.origin.x+screenBounds1.size.width));
            }
            if (delta2> delta) {
                screenChosen = 1;
            }
            if(screenChosen == 0){
                screenPosition_.x = screenBounds.origin.x;
                screenPosition_.y = screenBounds.origin.y;
                screenSize_.width = screenBounds.size.width;
                screenSize_.height = screenBounds.size.height;
            }else {
                screenPosition_.x = screenBounds1.origin.x;
                screenPosition_.y = screenBounds1.origin.y;
                screenSize_.width = screenBounds1.size.width;
                screenSize_.height = screenBounds1.size.height;
            }
        }       
    }
}

-(void)getVisibleScreenParams{
    NSArray * tempArray = [NSScreen screens];
    if ([tempArray count] ==1) {
        NSScreen * tempScreen = (NSScreen*)[tempArray objectAtIndex:0];
        screenVisibleSize_ = tempScreen.visibleFrame.size;
        screenVisiblePosition_ = tempScreen.visibleFrame.origin;
    }else {
        for(int i = 0;i<[tempArray count]; i++){
            NSScreen * tempScreen = (NSScreen*)[tempArray objectAtIndex:i];
            if (tempScreen.frame.origin.x == screenPosition_.x) {
                screenVisibleSize_ = tempScreen.visibleFrame.size;
                screenVisiblePosition_ = tempScreen.visibleFrame.origin;
                break;
            }
        }
    }

    
}

-(BOOL)getWindowParameters{
    NSLog(@"Get Window Parameter");
    BOOL error = FALSE;
	AXUIElementRef focusedApp;
	CFTypeRef position;
	CFTypeRef size;
    
	AXUIElementCopyAttributeValue(systemWideElement_,(CFStringRef)kAXFocusedApplicationAttribute,(CFTypeRef*)&focusedApp);
	if(AXUIElementCopyAttributeValue((AXUIElementRef)focusedApp,(CFStringRef)NSAccessibilityFocusedWindowAttribute,(CFTypeRef*)&focusedWindow_) == kAXErrorSuccess) {
		if(CFGetTypeID(focusedWindow_) == AXUIElementGetTypeID()) {
			if(AXUIElementCopyAttributeValue((AXUIElementRef)focusedWindow_,(CFStringRef)NSAccessibilityPositionAttribute,(CFTypeRef*)&position) != kAXErrorSuccess) {
				NSLog(@"Can't Retrieve Window Position");
                error = TRUE;
			}else {
                if(AXValueGetType(position) == kAXValueCGPointType) {
                    AXValueGetValue(position, kAXValueCGPointType, (void*)&windowPosition_);
                    NSLog(@"position x:%f, y:%f", windowPosition_.x, windowPosition_.y);
                }else {
                    error = TRUE;
                }                
            }

			if(AXUIElementCopyAttributeValue((AXUIElementRef)focusedWindow_,(CFStringRef)NSAccessibilitySizeAttribute,(CFTypeRef*)&size) != kAXErrorSuccess) {
				NSLog(@"Can't Retrieve Window Size");
                error = TRUE;
			}else {
                if(AXValueGetType(size) == kAXValueCGSizeType) {
                    AXValueGetValue(size, kAXValueCGSizeType, (void*)&windowSize_);
                    NSLog(@"size width:%f, height:%f", windowSize_.width, windowSize_.height);
                }else {
                    error = TRUE;
                }
            }
		}
	}else {
		NSLog(@"Problem with App");
	}
    if(!error){
		menuBarHeight_ = GetMBarHeight();
        [self chooseScreen];
        NSLog(@"Get Window Parameter Success");
    }else {
        NSLog(@"Get Window Parameter Failed");
    }
    return !error;
}

-(IBAction)shiftToLeftHalf:(id)sender{
    NSLog(@"Shifting To Left Half");
	if([self getWindowParameters]){
		[self getVisibleScreenParams];
        CFTypeRef position;
        CFTypeRef size;
        
		windowPosition_.x = screenVisiblePosition_.x;
		windowPosition_.y = ((screenVisiblePosition_.x ==0)? menuBarHeight_:0);
		position = (CFTypeRef)(AXValueCreate(kAXValueCGPointType, (const void *)&windowPosition_));
		
        windowSize_.width = ((screenVisibleSize_.width)/2);
        windowSize_.height = screenVisibleSize_.height;
        size = (CFTypeRef)(AXValueCreate(kAXValueCGSizeType, (const void *)&windowSize_));					
        NSLog(@"size2 width:%f, height:%f", windowSize_.width, windowSize_.height);

		if(AXUIElementSetAttributeValue((AXUIElementRef)focusedWindow_,(CFStringRef)NSAccessibilityPositionAttribute,(CFTypeRef*)position) != kAXErrorSuccess){
			NSLog(@"Position cannot be changed");
		}
		if(AXUIElementSetAttributeValue((AXUIElementRef)focusedWindow_,(CFStringRef)NSAccessibilitySizeAttribute,(CFTypeRef*)size) != kAXErrorSuccess){
			NSLog(@"Size cannot be modified");
		}
        
    }
    NSLog(@"Shifted To Left Half");
    focusedWindow_ = NULL;
    
}

-(IBAction)shiftToRightHalf:(id)sender{
    NSLog(@"Shifting To Right Half");
	if([self getWindowParameters]){
		[self getVisibleScreenParams];        
        CFTypeRef position;
        CFTypeRef size;
		windowPosition_.x = screenVisiblePosition_.x +(screenVisibleSize_.width/2);
		windowPosition_.y = ((screenVisiblePosition_.x ==0)? menuBarHeight_:0);
		position = (CFTypeRef)(AXValueCreate(kAXValueCGPointType, (const void *)&windowPosition_));
		
        windowSize_.width = ((screenVisibleSize_.width)/2);
        windowSize_.height = screenVisibleSize_.height;
        size = (CFTypeRef)(AXValueCreate(kAXValueCGSizeType, (const void *)&windowSize_));					
        
		if(AXUIElementSetAttributeValue((AXUIElementRef)focusedWindow_,(CFStringRef)NSAccessibilityPositionAttribute,(CFTypeRef*)position) != kAXErrorSuccess){
			NSLog(@"Position cannot be changed");
		}
		if(AXUIElementSetAttributeValue((AXUIElementRef)focusedWindow_,(CFStringRef)NSAccessibilitySizeAttribute,(CFTypeRef*)size) != kAXErrorSuccess){
			NSLog(@"Size cannot be modified");
		}
    }
    NSLog(@"Shifted To Right Half");
    focusedWindow_ = NULL;
    
}

-(IBAction)shiftToTopHalf:(id)sender{
    NSLog(@"Shifting To Top Half");
	if([self getWindowParameters]){
		[self getVisibleScreenParams];        
        CFTypeRef position;
        CFTypeRef size;
		windowPosition_.x = screenVisiblePosition_.x;
		windowPosition_.y = ((screenVisiblePosition_.x ==0)? menuBarHeight_:0);
		position = (CFTypeRef)(AXValueCreate(kAXValueCGPointType, (const void *)&windowPosition_));
		
        windowSize_.width = screenVisibleSize_.width;
        windowSize_.height = (screenVisibleSize_.height/2);
        size = (CFTypeRef)(AXValueCreate(kAXValueCGSizeType, (const void *)&windowSize_));					
        
		if(AXUIElementSetAttributeValue((AXUIElementRef)focusedWindow_,(CFStringRef)NSAccessibilityPositionAttribute,(CFTypeRef*)position) != kAXErrorSuccess){
			NSLog(@"Position cannot be changed");
		}
		if(AXUIElementSetAttributeValue((AXUIElementRef)focusedWindow_,(CFStringRef)NSAccessibilitySizeAttribute,(CFTypeRef*)size) != kAXErrorSuccess){
			NSLog(@"Size cannot be modified");
		}
    }
    NSLog(@"Shifted To Top Half");
    focusedWindow_ = NULL;
    
}

-(IBAction)shiftToBottomHalf:(id)sender{
    NSLog(@"Shifting To Bottom Half");
	if([self getWindowParameters]){
		[self getVisibleScreenParams];
        
        CFTypeRef position;
        CFTypeRef size;
        
		windowPosition_.x = screenVisiblePosition_.x;
		windowPosition_.y = (screenVisibleSize_.height/2)+((screenVisiblePosition_.x ==0)? menuBarHeight_:0);
		position = (CFTypeRef)(AXValueCreate(kAXValueCGPointType, (const void *)&windowPosition_));
		
        windowSize_.width = screenVisibleSize_.width;
        windowSize_.height = (screenVisibleSize_.height/2);
        size = (CFTypeRef)(AXValueCreate(kAXValueCGSizeType, (const void *)&windowSize_));					
        
		if(AXUIElementSetAttributeValue((AXUIElementRef)focusedWindow_,(CFStringRef)NSAccessibilityPositionAttribute,(CFTypeRef*)position) != kAXErrorSuccess){
			NSLog(@"Position cannot be changed");
		}
		if(AXUIElementSetAttributeValue((AXUIElementRef)focusedWindow_,(CFStringRef)NSAccessibilitySizeAttribute,(CFTypeRef*)size) != kAXErrorSuccess){
			NSLog(@"Size cannot be modified");
		}
    }
    NSLog(@"Shifted To Bottom Half");
    focusedWindow_ = NULL;
}

-(IBAction)shiftToTopLeft:(id)sender{
    NSLog(@"Shifting To Top Left");
	if([self getWindowParameters]){
        [self getVisibleScreenParams];
        CFTypeRef position;
        CFTypeRef size;
        
		windowPosition_.x = screenVisiblePosition_.x;
		windowPosition_.y = ((screenVisiblePosition_.x ==0)? menuBarHeight_:0);
		position = (CFTypeRef)(AXValueCreate(kAXValueCGPointType, (const void *)&windowPosition_));
		
        windowSize_.width = (screenVisibleSize_.width/2);
        windowSize_.height = (screenVisibleSize_.height/2);
        size = (CFTypeRef)(AXValueCreate(kAXValueCGSizeType, (const void *)&windowSize_));					
        
		if(AXUIElementSetAttributeValue((AXUIElementRef)focusedWindow_,(CFStringRef)NSAccessibilityPositionAttribute,(CFTypeRef*)position) != kAXErrorSuccess){
			NSLog(@"Position cannot be changed");
		}
		if(AXUIElementSetAttributeValue((AXUIElementRef)focusedWindow_,(CFStringRef)NSAccessibilitySizeAttribute,(CFTypeRef*)size) != kAXErrorSuccess){
			NSLog(@"Size cannot be modified");
		}
    }
    NSLog(@"Shifted To Top Left");
    focusedWindow_ = NULL;
    
}

-(IBAction)shiftToTopRight:(id)sender{
    NSLog(@"Shifting To Top Right");
	if([self getWindowParameters]){
        [self getVisibleScreenParams];
        
        CFTypeRef position;
        CFTypeRef size;
        
		windowPosition_.x = screenVisiblePosition_.x +(screenVisibleSize_.width/2);
		windowPosition_.y = ((screenVisiblePosition_.x ==0)? menuBarHeight_:0);
		position = (CFTypeRef)(AXValueCreate(kAXValueCGPointType, (const void *)&windowPosition_));
		
        windowSize_.width = (screenVisibleSize_.width/2);
        windowSize_.height = (screenVisibleSize_.height/2);
        size = (CFTypeRef)(AXValueCreate(kAXValueCGSizeType, (const void *)&windowSize_));					
        
		if(AXUIElementSetAttributeValue((AXUIElementRef)focusedWindow_,(CFStringRef)NSAccessibilityPositionAttribute,(CFTypeRef*)position) != kAXErrorSuccess){
			NSLog(@"Position cannot be changed");
		}
		if(AXUIElementSetAttributeValue((AXUIElementRef)focusedWindow_,(CFStringRef)NSAccessibilitySizeAttribute,(CFTypeRef*)size) != kAXErrorSuccess){
			NSLog(@"Size cannot be modified");
		}
    }
    NSLog(@"Shifted To Top Right");
    focusedWindow_ = NULL;
    
}

-(IBAction)shiftToBottomLeft:(id)sender{
    NSLog(@"Shifting To Botom Left");
	if([self getWindowParameters]){
        [self getVisibleScreenParams];
        
        CFTypeRef position;
        CFTypeRef size;
        
		windowPosition_.x = screenVisiblePosition_.x;
		windowPosition_.y = (screenVisibleSize_.height/2)+((screenVisiblePosition_.x ==0)? menuBarHeight_:0);
		position = (CFTypeRef)(AXValueCreate(kAXValueCGPointType, (const void *)&windowPosition_));
		
        windowSize_.width = (screenVisibleSize_.width/2);
        windowSize_.height = (screenVisibleSize_.height/2);
        size = (CFTypeRef)(AXValueCreate(kAXValueCGSizeType, (const void *)&windowSize_));					
        
		if(AXUIElementSetAttributeValue((AXUIElementRef)focusedWindow_,(CFStringRef)NSAccessibilityPositionAttribute,(CFTypeRef*)position) != kAXErrorSuccess){
			NSLog(@"Position cannot be changed");
		}
		if(AXUIElementSetAttributeValue((AXUIElementRef)focusedWindow_,(CFStringRef)NSAccessibilitySizeAttribute,(CFTypeRef*)size) != kAXErrorSuccess){
			NSLog(@"Size cannot be modified");
		}
    }
    NSLog(@"Shifted To Bottom Left");
    focusedWindow_ = NULL;
    
}

-(IBAction)shiftToBottomRight:(id)sender{
    NSLog(@"Shifting To Botom Right");
	if([self getWindowParameters]){
        [self getVisibleScreenParams];
        
        CFTypeRef position;
        CFTypeRef size;
        
		windowPosition_.x = screenVisiblePosition_.x +(screenVisibleSize_.width/2);
		windowPosition_.y = (screenVisibleSize_.height/2)+((screenVisiblePosition_.x ==0)? menuBarHeight_:0);
		position = (CFTypeRef)(AXValueCreate(kAXValueCGPointType, (const void *)&windowPosition_));
		
        windowSize_.width = (screenVisibleSize_.width/2);
        windowSize_.height = (screenVisibleSize_.height/2);
        size = (CFTypeRef)(AXValueCreate(kAXValueCGSizeType, (const void *)&windowSize_));					
        
		if(AXUIElementSetAttributeValue((AXUIElementRef)focusedWindow_,(CFStringRef)NSAccessibilityPositionAttribute,(CFTypeRef*)position) != kAXErrorSuccess){
			NSLog(@"Position cannot be changed");
		}
		if(AXUIElementSetAttributeValue((AXUIElementRef)focusedWindow_,(CFStringRef)NSAccessibilitySizeAttribute,(CFTypeRef*)size) != kAXErrorSuccess){
			NSLog(@"Size cannot be modified");
		}
    }
    NSLog(@"Shifted To Bottom Right");
    focusedWindow_ = NULL;
    
}

-(IBAction)shiftToCenter:(id)sender{
    NSLog(@"Shifting To Center");
	if([self getWindowParameters]){
        [self getVisibleScreenParams];
        
        CFTypeRef position;
        
		windowPosition_.x = screenVisiblePosition_.x+(screenVisibleSize_.width/2)-(windowSize_.width/2);
		windowPosition_.y = ((screenVisiblePosition_.x ==0)? menuBarHeight_:0)+(screenVisibleSize_.height/2)-(windowSize_.height/2);
		position = (CFTypeRef)(AXValueCreate(kAXValueCGPointType, (const void *)&windowPosition_));
        
		if(AXUIElementSetAttributeValue((AXUIElementRef)focusedWindow_,(CFStringRef)NSAccessibilityPositionAttribute,(CFTypeRef*)position) != kAXErrorSuccess){
			NSLog(@"Position cannot be changed");
		}
    }
    NSLog(@"Shifted To Center");
    focusedWindow_ = NULL;
}

-(IBAction)fullScreen:(id)sender{
    NSLog(@"Shifting To Full Screen");
	if([self getWindowParameters]){
        [self getVisibleScreenParams];
        CFTypeRef position;
        CFTypeRef size;
        
		windowPosition_.x = screenVisiblePosition_.x;
		windowPosition_.y = ((screenVisiblePosition_.x ==0)? menuBarHeight_:0);
		position = (CFTypeRef)(AXValueCreate(kAXValueCGPointType, (const void *)&windowPosition_));
		
        windowSize_.width = screenVisibleSize_.width;
        windowSize_.height = screenVisibleSize_.height;
        size = (CFTypeRef)(AXValueCreate(kAXValueCGSizeType, (const void *)&windowSize_));					
        
		if(AXUIElementSetAttributeValue((AXUIElementRef)focusedWindow_,(CFStringRef)NSAccessibilityPositionAttribute,(CFTypeRef*)position) != kAXErrorSuccess){
			NSLog(@"Position cannot be changed");
		}
		if(AXUIElementSetAttributeValue((AXUIElementRef)focusedWindow_,(CFStringRef)NSAccessibilitySizeAttribute,(CFTypeRef*)size) != kAXErrorSuccess){
			NSLog(@"Size cannot be modified");
		}
    }
    NSLog(@"Shifted To Full Screen");
    focusedWindow_ = NULL;
}

-(WindowSizer *)init{
	if(self = [super init]){;
		systemWideElement_ = AXUIElementCreateSystemWide();
	}
	return self;
}

@end
