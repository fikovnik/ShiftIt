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
#import "FMTDefines.h"
#import "NSScreen+DisplayName.h"

NSRect ShiftIt_Left(NSSize screenSize, NSRect windowRect, AXUIElementRef windowRef) {
	NSRect r;
	
	r.origin.x = 0;
	r.origin.y = 0;
	
	r.size.width = screenSize.width / 2;
	r.size.height = screenSize.height;
	
	return r;
}

NSRect ShiftIt_Right(NSSize screenSize, NSRect windowRect, AXUIElementRef windowRef) {
	NSRect r;
	
	r.origin.x = screenSize.width/2;
	r.origin.y = 0;
	
	r.size.width = screenSize.width / 2;
	r.size.height = screenSize.height;

	return r;
}

NSRect ShiftIt_Top(NSSize screenSize, NSRect windowRect, AXUIElementRef windowRef) {
	NSRect r;
	
	r.origin.x = 0;
	r.origin.y = 0;
	
	r.size.width = screenSize.width;
	r.size.height = screenSize.height / 2;
	
	return r;
}

NSRect ShiftIt_Bottom(NSSize screenSize, NSRect windowRect, AXUIElementRef windowRef) {
	NSRect r;
	
	r.origin.x = 0;
	r.origin.y = screenSize.height / 2;
	
	r.size.width = screenSize.width;
	r.size.height = screenSize.height / 2;
	
	return r;
}

NSRect ShiftIt_TopLeft(NSSize screenSize, NSRect windowRect, AXUIElementRef windowRef) {
	NSRect r;
	
	r.origin.x = 0;
	r.origin.y = 0;
	
	r.size.width = screenSize.width / 2;
	r.size.height = screenSize.height / 2;
	
	return r;
}

NSRect ShiftIt_TopRight(NSSize screenSize, NSRect windowRect, AXUIElementRef windowRef) {
	NSRect r;
	
	r.origin.x = screenSize.width / 2;
	r.origin.y = 0;
	
	r.size.width = screenSize.width / 2;
	r.size.height = screenSize.height / 2;
	
	return r;
}

NSRect ShiftIt_BottomLeft(NSSize screenSize, NSRect windowRect, AXUIElementRef windowRef) {
	NSRect r;
	
	r.origin.x = 0;
	r.origin.y = screenSize.height / 2;
	
	r.size.width = screenSize.width / 2;
	r.size.height = screenSize.height / 2;
	
	return r;
}

NSRect ShiftIt_BottomRight(NSSize screenSize, NSRect windowRect, AXUIElementRef windowRef) {
	NSRect r;
	
	r.origin.x = screenSize.width / 2;
	r.origin.y = screenSize.height / 2;
	
	r.size.width = screenSize.width / 2;
	r.size.height = screenSize.height / 2;
	
	return r;
}

NSRect ShiftIt_FullScreen(NSSize screenSize, NSRect windowRect, AXUIElementRef windowRef) {
	NSRect r;
	
	r.origin.x = 0;
	r.origin.y = 0;
	
	r.size.width = screenSize.width;
	r.size.height = screenSize.height;
	
	return r;
}

NSRect ShiftIt_Center(NSSize screenSize, NSRect windowRect, AXUIElementRef windowRef) {
	NSRect r;
	
	r.origin.x = (screenSize.width / 2)-(windowRect.size.width / 2);
	r.origin.y = (screenSize.height / 2)-(windowRect.size.height / 2);	
	
	r.size = windowRect.size;
	
	return r;
}

NSRect ShiftIt_AlterDisplay(NSSize screenSize, NSRect windowRect, AXUIElementRef windowRef) {
	CGDirectDisplayID currentDisplayID;
	CGDisplayCount count;
	
	if (CGGetDisplaysWithRect(windowRect, 1, &currentDisplayID, &count) == kCGErrorSuccess) {
		NSArray *screens=[NSScreen screens];
		NSScreen *currentScreen = nil;
		int i, displayIndex=0, screenCount=[screens count];
		
		for(i=0; i<screenCount; i++){
			NSScreen *check=[screens objectAtIndex:i];
			NSNumber *checkDisplayID = [[check deviceDescription] objectForKey:@"NSScreenNumber"];
			
			if ([checkDisplayID intValue] == currentDisplayID) {
				currentScreen=check;
				displayIndex=i;
				break;
			}
		}
		
		displayIndex = (displayIndex + 1) % screenCount;
		
		NSScreen *nextScreen = [[NSScreen screens] objectAtIndex:displayIndex];
		NSNumber *nextDisplayID = [[nextScreen deviceDescription] objectForKey:@"NSScreenNumber"];
		CGDirectDisplayID CGNextDisplayID = (CGDirectDisplayID) [nextDisplayID intValue];
			
		CGRect nextCGRect = CGDisplayBounds(CGNextDisplayID);		
		NSSize nextScreenSize = [nextScreen visibleFrame].size;
		
		windowRect.size.width = nextScreenSize.width / 2;
		windowRect.size.height = nextScreenSize.height / 2;		
		
		windowRect.origin.x = nextCGRect.origin.x;
		windowRect.origin.y = nextCGRect.origin.y;				
	}
	
	return windowRect;
}