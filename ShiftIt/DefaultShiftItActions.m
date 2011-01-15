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

CGFloat equalsWithinTolerance(CGFloat a, CGFloat b) {
	return abs(a-b) < 10; // test absolute within 5 pixel (units or dots?)
}

NSRect ShiftIt_Left(NSSize screenSize, NSRect windowRect) {
	NSRect r;
	
	r.origin.x = 0;
	r.origin.y = 0;

	r.size.width = screenSize.width / 2;
	r.size.height = screenSize.height;
	
	return r;
}

NSRect ShiftIt_LeftCycle(NSSize screenSize, NSRect windowRect) {
	NSRect r;
	
	r.origin.x = 0;
	r.origin.y = 0;

	// Cycle in order 1/2 to 2/3 to 1/3
	if (!equalsWithinTolerance(windowRect.origin.x, 0)) // init 
		r.size.width = screenSize.width * 1.0 / 2.0;
	else if (equalsWithinTolerance(windowRect.size.width, screenSize.width * 1.0 / 2.0 ))
		r.size.width = screenSize.width * 2.0 / 3.0;
	else if (equalsWithinTolerance(windowRect.size.width, screenSize.width * 2.0 / 3.0 ))
		r.size.width = screenSize.width * 1.0 / 3.0;
	else 
		r.size.width = screenSize.width * 1.0 / 2.0;
	
	r.size.height = screenSize.height;
	
	return r;
}

NSRect ShiftIt_Right(NSSize screenSize, NSRect windowRect) {
	NSRect r;
	
	r.origin.x = screenSize.width / 2;
	r.origin.y = 0;
	
	r.size.width = screenSize.width / 2;
	r.size.height = screenSize.height;

	return r;
}

NSRect ShiftIt_RightCycle(NSSize screenSize, NSRect windowRect) {
	NSRect r;
	
	r.origin.y = 0;	
	r.size.height = screenSize.height;
	
	// Cycle in order 1/2 to 1/3 to 2/3 and back 
	if (!equalsWithinTolerance(windowRect.origin.x+windowRect.size.width, screenSize.width)) { // init
		r.origin.x = screenSize.width * 1.0 / 2.0;
		r.size.width = screenSize.width * 1.0 / 2.0;
	} else if (equalsWithinTolerance(windowRect.origin.x, screenSize.width * 1.0 / 2.0 )) {
		r.origin.x = screenSize.width * 2.0 / 3.0;
		r.size.width = screenSize.width * 1.0 / 3.0;
	} else if (equalsWithinTolerance(windowRect.origin.x, screenSize.width * 2.0 / 3.0 )) {
		r.origin.x = screenSize.width * 1.0 / 3.0;
		r.size.width = screenSize.width * 2.0 / 3.0;
	} else {
		r.origin.x = screenSize.width * 1.0 / 2.0;
		r.size.width = screenSize.width * 1.0 / 2.0;
	}
	
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

NSRect ShiftIt_TopCycle(NSSize screenSize, NSRect windowRect) {
	NSRect r;
	
	r.origin.x = 0;
	r.origin.y = 0;
	
	r.size.width = screenSize.width;
	
	// Cycle in order 1/2 to 1/3 to 2/3
	if (!equalsWithinTolerance(windowRect.origin.y, 0)) // init 
		r.size.height = screenSize.height * 1.0 / 2.0;
	else if (equalsWithinTolerance(windowRect.size.height, screenSize.height * 1.0 / 2.0 ))
		r.size.height = screenSize.height * 1.0 / 3.0;
	else if (equalsWithinTolerance(windowRect.size.height, screenSize.height * 1.0 / 3.0 ))
		r.size.height = screenSize.height * 2.0 / 3.0;
	else 
		r.size.height = screenSize.height * 1.0 / 2.0;
	
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

NSRect ShiftIt_BottomCycle(NSSize screenSize, NSRect windowRect) {
	NSRect r;
	
	r.origin.x = 0;
	r.origin.y = screenSize.height / 2;
	
	r.size.width = screenSize.width;
	r.size.height = screenSize.height / 2;
	
	// Cycle in order 1/2 to 1/3 to 2/3 and back 
	if (!equalsWithinTolerance(windowRect.origin.y+windowRect.size.height, screenSize.height)) { // init
		r.origin.y = screenSize.height * 1.0 / 2.0;
		r.size.height = screenSize.height * 1.0 / 2.0;
	} else if (equalsWithinTolerance(windowRect.origin.y, screenSize.height * 1.0 / 2.0 )) {
		r.origin.y = screenSize.height * 1.0 / 3.0;
		r.size.height = screenSize.height * 2.0 / 3.0;
	} else if (equalsWithinTolerance(windowRect.origin.y, screenSize.height * 1.0 / 3.0 )) {
		r.origin.y = screenSize.height * 2.0 / 3.0;
		r.size.height = screenSize.height * 1.0 / 3.0;
	} else {
		r.origin.y = screenSize.height * 1.0 / 2.0;
		r.size.height = screenSize.height * 1.0 / 2.0;
	}

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

NSRect ShiftIt_FullHeight(NSSize screenSize, NSRect windowRect) {
	NSRect r;
	
	r.origin.x = windowRect.origin.x;
	r.origin.y = 0;
	
	r.size.width = windowRect.size.width;
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
