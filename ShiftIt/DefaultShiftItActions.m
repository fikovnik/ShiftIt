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
#import "WindowSizer.h"

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

#define EqualWithVicinity(a,b,e) ((a) >= ((b) - (e)) && (a) <= ((b) + (e)))

#define EqualPoints(p1,x1,y1,e) (EqualWithVicinity(((p1).x), (x1), (e)) && EqualWithVicinity(((p1).y), (y1), (e)))

NSRect ShiftIt_IncreaseReduce_(NSSize screenSize, NSRect windowRect, float kw, float kh, BOOL increase) {	
	FMTAssert(kw > 0, @"kw must be greater than zero");
	FMTAssert(kh > 0, @"kh must be greater than zero");
	
	NSRect r = windowRect;
	
	// 1: increase, -1: reduce
	int inc = increase ? 1 : -1;
	int e = 2;
		
	// try to determine what is the anchor
	if (EqualPoints(r.origin,0,0,e) 
		&& EqualWithVicinity(r.size.width, screenSize.width, e)
		&& EqualWithVicinity(r.size.height, screenSize.height, e)) {
		// fullscreen

		r.size.width = windowRect.size.width + inc * (kw);			
		r.size.height = windowRect.size.height + inc * (kh);			
		r.origin.x -= inc * (kw/2);
		r.origin.y -= inc * (kh/2);
	} else if (EqualPoints(r.origin,0,0,e) 
			   && EqualWithVicinity(r.size.height, screenSize.height, e)) {
		// left
		
		r.size.width = windowRect.size.width + inc * (kw);			
	} else if (EqualPoints(r.origin, screenSize.width - r.size.width, 0, e) 
			   && EqualWithVicinity(r.size.height, screenSize.height, e)) {
		// right
		
		r.size.width = windowRect.size.width + inc * (kw);			
		r.origin.x = screenSize.width - r.size.width;
	} else if (EqualPoints(r.origin,0,0,e) 
			   && EqualWithVicinity(r.size.width, screenSize.width, e)) {
		// top
		
		r.size.height = windowRect.size.height + inc * (kh);
	} else if (EqualPoints(r.origin, 0, screenSize.height - r.size.height,e)
			   && r.size.width == screenSize.width) {
		// bottom
		
		r.size.height = windowRect.size.height + inc * (kh);			
		r.origin.y = screenSize.height - r.size.height;
	} else if (EqualPoints(r.origin,0,0,e)) {
		// top left
		
		r.size.width = windowRect.size.width + inc * (kw);			
		r.size.height = windowRect.size.height + inc * (kh);
	} else if (EqualPoints(r.origin, screenSize.width - r.size.width, 0, e)) {
		// top right
		
		r.size.width = windowRect.size.width + inc * (kw);			
		r.size.height = windowRect.size.height + inc * (kh);
		r.origin.x = screenSize.width - r.size.width;		
	} else if (EqualPoints(r.origin, 0, screenSize.height - r.size.height, e)) {
		// bottom left
		
		r.size.width = windowRect.size.width + inc * (kw);			
		r.size.height = windowRect.size.height + inc * (kh);			
		r.origin.y = screenSize.height - r.size.height;		
	} else if (EqualPoints(r.origin, screenSize.width - r.size.width, screenSize.height - r.size.height,e)) {
		// bottom right
		
		r.size.width = windowRect.size.width + inc * (kw);			
		r.size.height = windowRect.size.height + inc * (kh);			
		r.origin.x = screenSize.width - r.size.width;
		r.origin.y = screenSize.height - r.size.height;
	} else {
		// other 
		
		r.size.width = windowRect.size.width + inc * (kw);			
		r.size.height = windowRect.size.height + inc * (kh);			
		r.origin.x -= inc * (kw/2);
		r.origin.y -= inc * (kh/2);
	}
	
	// check window rect - constraine by the screen size
	r.size.width = r.size.width < kw ? kw : r.size.width;
	r.size.width = r.size.width > screenSize.width ? screenSize.width : r.size.width;
	
	r.size.height = r.size.height < kh ? kh : r.size.height;
	r.size.height = r.size.height > screenSize.height ? screenSize.height : r.size.height;

	r.origin.x = r.origin.x < 0 ? 0 : r.origin.x;
	r.origin.x = r.origin.x > screenSize.width - r.size.width ? screenSize.width - r.size.width : r.origin.x;

	r.origin.y = r.origin.y < 0 ? 0 : r.origin.y;
	r.origin.y = r.origin.y > screenSize.height - r.size.height ? screenSize.height - r.size.height : r.origin.y;
		
	return r;	
}

NSRect ShiftIt_Increase(NSSize screenSize, NSRect windowRect) {
	return ShiftIt_IncreaseReduce_(screenSize, windowRect, screenSize.width/12, screenSize.height/12, YES);
}

NSRect ShiftIt_Reduce(NSSize screenSize, NSRect windowRect) {
	return ShiftIt_IncreaseReduce_(screenSize, windowRect, screenSize.width/12, screenSize.height/12, NO);
}
