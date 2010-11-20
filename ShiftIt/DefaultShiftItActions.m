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

extern short GetMBarHeight(void);

NSRect ShiftIt_Left(NSSize screenSize, NSRect windowRect) {
	NSRect r;
	
	r.origin.x = 0;
	r.origin.y = 0;
	
	r.size.width = screenSize.width / 2;
	r.size.height = screenSize.height;
	
	return r;
}

NSRect ShiftIt_Right(NSSize screenSize, NSRect windowRect) {
	NSRect r;
	
	r.origin.x = screenSize.width/2;
	r.origin.y = 0;
	
	r.size.width = screenSize.width / 2;
	r.size.height = screenSize.height;

	return r;
}

NSRect ShiftIt_Top(NSSize screenSize, NSRect windowRect) {
	NSRect r;
	
	r.origin.x = 0;
	r.origin.y = 0;
	
	r.size.width = screenSize.width;
	r.size.height = screenSize.height / 2;
	
	return r;
}

NSRect ShiftIt_Bottom(NSSize screenSize, NSRect windowRect) {
	NSRect r;
	
	r.origin.x = 0;
	r.origin.y = screenSize.height / 2;
	
	r.size.width = screenSize.width;
	r.size.height = screenSize.height / 2;
	
	return r;
}

NSRect ShiftIt_TopLeft(NSSize screenSize, NSRect windowRect) {
	NSRect r;
	
	r.origin.x = 0;
	r.origin.y = 0;
	
	r.size.width = screenSize.width / 2;
	r.size.height = screenSize.height / 2;
	
	return r;
}

NSRect ShiftIt_TopRight(NSSize screenSize, NSRect windowRect) {
	NSRect r;
	
	r.origin.x = screenSize.width / 2;
	r.origin.y = 0;
	
	r.size.width = screenSize.width / 2;
	r.size.height = screenSize.height / 2;
	
	return r;
}

NSRect ShiftIt_BottomLeft(NSSize screenSize, NSRect windowRect) {
	NSRect r;
	
	r.origin.x = 0;
	r.origin.y = screenSize.height / 2;
	
	r.size.width = screenSize.width / 2;
	r.size.height = screenSize.height / 2;
	
	return r;
}

NSRect ShiftIt_BottomRight(NSSize screenSize, NSRect windowRect) {
	NSRect r;
	
	r.origin.x = screenSize.width / 2;
	r.origin.y = screenSize.height / 2;
	
	r.size.width = screenSize.width / 2;
	r.size.height = screenSize.height / 2;
	
	return r;
}

NSRect ShiftIt_FullScreen(NSSize screenSize, NSRect windowRect) {
	NSRect r;
	
	r.origin.x = 0;
	r.origin.y = 0;
	
	r.size.width = screenSize.width;
	r.size.height = screenSize.height;
	
	return r;
}

NSRect ShiftIt_Center(NSSize screenSize, NSRect windowRect) {
	NSRect r;
	
	r.origin.x = (screenSize.width / 2)-(windowRect.size.width / 2);
	r.origin.y = (screenSize.height / 2)-(windowRect.size.height / 2);	
	
	r.size = windowRect.size;
	
	return r;
}

NSRect ShiftIt_Wider(NSSize screenSize, NSRect windowRect) {
	NSRect r;
	
	float menuBarHeight = GetMBarHeight();
	
	int whichSide;
	(windowRect.origin.x == 0) ? (whichSide = 0) : (whichSide = 1);
	
	switch (whichSide) {
		case 0: // window origin is in left region			
			r.size.width = windowRect.size.width * 1.05;
			r.size.height = windowRect.size.height;
			
			r.origin.x = windowRect.origin.x;
			r.origin.y = windowRect.origin.y - menuBarHeight;
			
			break;
		case 1: // window origin is in right region
			r.size.width = windowRect.size.width * 1.05;
			r.size.height = windowRect.size.height;
			
			r.origin.x = screenSize.width - r.size.width;
			r.origin.y = windowRect.origin.y - menuBarHeight;
						
			break;
		default:
			break;
	}
	
	return r;
}

NSRect ShiftIt_Taller(NSSize screenSize, NSRect windowRect) {
	NSRect r;
	
	float menuBarHeight = GetMBarHeight();
	
	// detect which side of the window is touching the side of the display
	int topOrBottom;
	(windowRect.origin.y - menuBarHeight == 0) ? (topOrBottom = 0) : (topOrBottom = 1);
	
	switch (topOrBottom) {
		case 0: // window origin is in upper region			
			r.size.width = windowRect.size.width;
			r.size.height = windowRect.size.height * 1.05;
			
			r.origin.x = windowRect.origin.x;
			r.origin.y = windowRect.origin.y - menuBarHeight;
			
			break;
		case 1: // window origin is in lower region
			r.size.width = windowRect.size.width;
			r.size.height = windowRect.size.height * 1.05;
			
			r.origin.x = 0;
			r.origin.y = screenSize.height - r.size.height;
			
			break;
		default:
			break;
	}
	
	return r;
}
