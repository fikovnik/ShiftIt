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

NSRect ShiftIt_Left(NSSize screenSize, NSRect windowRect) {
	NSRect r;
	r.size.height = windowRect.size.height;
	r.origin.y = windowRect.origin.y;
	
	if(windowRect.origin.x < 5) {
		r.size.width = SizeIt(windowRect.size.width, screenSize.width); 
	} else {
		r.size.width = windowRect.size.width;
	}
	r.origin.x = 0;
	
	return r;
}

NSRect ShiftIt_Right(NSSize screenSize, NSRect windowRect) {
	NSRect r;
	r.size.height = windowRect.size.height;
	r.origin.y = windowRect.origin.y;
	
	if(fabsf(windowRect.origin.x + windowRect.size.width - screenSize.width) < 5) {
		r.size.width = SizeIt(windowRect.size.width, screenSize.width); 
	} else {
		r.size.width = windowRect.size.width;
	}
	r.origin.x = screenSize.width - r.size.width;
	
	return r;
}

NSRect ShiftIt_Top(NSSize screenSize, NSRect windowRect) {
	NSRect r;
	r.size.width = windowRect.size.width;
	r.origin.x = windowRect.origin.x;
	
	if(windowRect.origin.y < 5) {
		r.size.height = SizeIt(windowRect.size.height, screenSize.height); 
	} else {
		r.size.height = windowRect.size.height;
	}
	r.origin.y = 0;
	
	return r;
}

NSRect ShiftIt_Bottom(NSSize screenSize, NSRect windowRect) {
	NSRect r;
	r.size.width = windowRect.size.width;
	r.origin.x = windowRect.origin.x;
	
	if( fabsf(windowRect.origin.y + windowRect.size.height - screenSize.height) < 5 ){
		r.size.height = SizeIt(windowRect.size.height, screenSize.height); 
	} else {
		r.size.height = windowRect.size.height;
	}
	r.origin.y = screenSize.height - r.size.height;
	
	return r;
}


NSRect ShiftIt_Left_Two_Thirds(NSSize screenSize, NSRect windowRect) {
	NSRect r;
	    
	r.origin.x = 0;
	r.origin.y = 0;
	    
	r.size.width = 2 * screenSize.width / 3;
	r.size.height = screenSize.height;
	    
	return r;
}

NSRect ShiftIt_Right_One_Third(NSSize screenSize, NSRect windowRect) {
	NSRect r;
	    
	r.origin.x = 2 * screenSize.width/3;
	r.origin.y = 0;
	    
	r.size.width = screenSize.width / 3;
	r.size.height = screenSize.height;
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

float SizeIt(float part, float full) {
	if ( fabsf(part - full / 2) < 5 ) {
		return full / 3;
	} else if ( fabsf(part - full / 3) < 5 ) {
		return full;
	} else if ( fabsf(part - full) < 5 ) {
		return 2*full/3;
	} else {
		return full / 2;
	}
}
