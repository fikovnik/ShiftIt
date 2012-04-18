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

#define CYCLE_FRACTION_HORIZ (1.0/10.0) // will cycle about 2/5 and 3/5
#define CYCLE_FRACTION_VERT (1.0/6.0) // will cycle about 1/3 and 2/3

// Hozirontal Zone Fractions
#define LEFT_ZONE_FRACTION (0.0)
#define MIDDLE_LEFT_ZONE_FRACTION (0.5-CYCLE_FRACTION_HORIZ)
#define MIDDLE_ZONE_FRACTION (0.5)
#define MIDDLE_RIGHT_ZONE_FRACTION (0.5+CYCLE_FRACTION_HORIZ)
#define RIGHT_ZONE_FRACTION (1.0)

// Vertical Zone Fractions
#define TOP_ZONE_FRACTION (0.0)
#define MIDDLE_TOP_ZONE_FRACTION (0.5-CYCLE_FRACTION_HORIZ)
#define MIDDLE_BOTTOM_ZONE_FRACTION (0.5+CYCLE_FRACTION_HORIZ)
#define BOTTOM_ZONE_FRACTION (1.0)

#define HZONE(a) findHorizZone(a, screenSize)

CGFloat equalsWithinTolerance(CGFloat a, CGFloat b) {
	return abs(a-b) < 10; // test absolute within 5 pixel (units or dots?)
}

typedef enum { 
	Left, // 0
	MiddleLeft, 
	Middle, 
	MiddleRight, 
	Right,
	NoZone // 5
} Zone;

Zone findHorizZone(CGFloat a, NSSize screenSize) {
	if (equalsWithinTolerance(a, 0))
		return Left;
	else if (equalsWithinTolerance(a, screenSize.width * (0.5-CYCLE_FRACTION_HORIZ)))
		return MiddleLeft;
	else if (equalsWithinTolerance(a, screenSize.width * (0.5)))
		return Middle;
	else if (equalsWithinTolerance(a, screenSize.width * (0.5+CYCLE_FRACTION_HORIZ)))
		return MiddleRight;
	else if (equalsWithinTolerance(a, screenSize.width ))
		return Right;
	else
		return NoZone;
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
	r.size.height = screenSize.height;

	// Cycle in order 1/2 and 1/2 (-/+) fraction offset from center
	Zone originZone = HZONE(windowRect.origin.x);
	Zone widthZoneSize = HZONE(windowRect.size.width);
	
	NSLog(@"originZone: %d", originZone);
	NSLog(@"widthZoneSize: %d", widthZoneSize);
	
	CGFloat newWidthFrac = MIDDLE_ZONE_FRACTION;
	
	if (originZone == NoZone) // initialize
		newWidthFrac = MIDDLE_ZONE_FRACTION;
	else if (originZone != Left) { // flip sides
		switch (widthZoneSize) {
			case MiddleLeft:  newWidthFrac = MIDDLE_RIGHT_ZONE_FRACTION; break;
			case MiddleRight: newWidthFrac = MIDDLE_LEFT_ZONE_FRACTION; break;
		}
	} 
	else { // cycle
		switch (widthZoneSize) {
			case Middle:      newWidthFrac = MIDDLE_LEFT_ZONE_FRACTION; break;
			case MiddleLeft:  newWidthFrac = MIDDLE_RIGHT_ZONE_FRACTION; break;
			case MiddleRight: newWidthFrac = MIDDLE_ZONE_FRACTION; break;
		}
	}
	
	r.size.width = screenSize.width * newWidthFrac;
		
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
	
	// // Cycle in order 1/2 and 1/2 (+/-) fraction offset from center
	// if (!equalsWithinTolerance(windowRect.origin.x+windowRect.size.width, screenSize.width)) { // init
	// 	r.origin.x = screenSize.width * 0.5;
	// 	r.size.width = screenSize.width * 0.5;
	// } else if (equalsWithinTolerance(windowRect.origin.x, screenSize.width * 0.5 )) {
	// 	r.origin.x = screenSize.width * (0.5 + CYCLE_FRACTION_HORIZ);
	// 	r.size.width = screenSize.width * (0.5 - CYCLE_FRACTION_HORIZ);
	// } else if (equalsWithinTolerance(windowRect.origin.x, screenSize.width * (0.5 + CYCLE_FRACTION_HORIZ) )) {
	// 	r.origin.x = screenSize.width * (0.5 - CYCLE_FRACTION_HORIZ);
	// 	r.size.width = screenSize.width * (0.5 + CYCLE_FRACTION_HORIZ);
	// } else {
	// 	r.origin.x = screenSize.width * 0.5;
	// 	r.size.width = screenSize.width * 0.5;
	// }
	
	// Cycle in order 1/2 and 1/2 (-/+) fraction offset from center
	Zone originZone = HZONE(windowRect.origin.x);
	Zone widthZoneSize = HZONE(windowRect.size.width);
	
	NSLog(@"originZone: %d", originZone);
	NSLog(@"widthZoneSize: %d", widthZoneSize);
	
	CGFloat newOriginFrac = MIDDLE_ZONE_FRACTION;
	CGFloat newWidthFrac = MIDDLE_ZONE_FRACTION;
	
	if (originZone == NoZone) // initialize
		newWidthFrac = MIDDLE_ZONE_FRACTION;
	else if (originZone == Left) { // flip sides
		switch (widthZoneSize) {
			case MiddleLeft:  newWidthFrac = MIDDLE_RIGHT_ZONE_FRACTION; break;
			case MiddleRight: newWidthFrac = MIDDLE_LEFT_ZONE_FRACTION; break;
			default:          newWidthFrac = MIDDLE_ZONE_FRACTION;
		}
	} 
	else { // cycle
		switch (widthZoneSize) {
			case Middle:      newWidthFrac = MIDDLE_LEFT_ZONE_FRACTION; break;
			case MiddleLeft:  newWidthFrac = MIDDLE_RIGHT_ZONE_FRACTION; break;
			case MiddleRight: newWidthFrac = MIDDLE_ZONE_FRACTION; break;
		}
	}
	
	r.size.width = screenSize.width * newWidthFrac;
	r.origin.x = screenSize.width - r.size.width;
	
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
	
	// Cycle in order 1/2 and 1/2 (+/-) fraction offset from center
	if (!equalsWithinTolerance(windowRect.origin.y, 0)) // init 
		r.size.height = screenSize.height * MIDDLE_ZONE_FRACTION;
	else if (equalsWithinTolerance(windowRect.size.height, screenSize.height * MIDDLE_ZONE_FRACTION ))
		r.size.height = screenSize.height; // add fullscreen extra cycle
	else 
		r.size.height = screenSize.height * MIDDLE_ZONE_FRACTION;
	
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
	
	// Cycle in order 1/2 and 1/2 (+/-) fraction offset from center
	if (!equalsWithinTolerance(windowRect.origin.y+windowRect.size.height, screenSize.height)) { // init
		r.origin.y = screenSize.height * MIDDLE_ZONE_FRACTION;
		r.size.height = screenSize.height * MIDDLE_ZONE_FRACTION;
	} else if (equalsWithinTolerance(windowRect.origin.y, screenSize.height * MIDDLE_ZONE_FRACTION )) {
		r.origin.y = 0;
		r.size.height = screenSize.height;
	} else {
		r.origin.y = screenSize.height * MIDDLE_ZONE_FRACTION;
		r.size.height = screenSize.height * MIDDLE_ZONE_FRACTION;
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
