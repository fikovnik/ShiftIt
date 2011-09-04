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
#import "ShiftIt.h"
#import "FMTDefines.h"
#import "ShiftItWindowManager.h"
#import "SimpleShiftItAction.h"

const SimpleShiftItActionBlock shiftItLeft = ^NSRect(NSRect windowRect,NSSize screenSize) {
	NSRect r;
	
	r.origin.x = 0;
	r.origin.y = 0;
	
	r.size.width = screenSize.width / 2;
	r.size.height = screenSize.height;
	
	return r;    
};

const SimpleShiftItActionBlock shiftItRight = ^NSRect(NSRect windowRect,NSSize screenSize) {
	NSRect r;
	
	r.origin.x = screenSize.width/2;
	r.origin.y = 0;
	
	r.size.width = screenSize.width / 2;
	r.size.height = screenSize.height;
	
	return r;
};

const SimpleShiftItActionBlock shiftItTop = ^NSRect(NSRect windowRect,NSSize screenSize) {
	NSRect r;
	
	r.origin.x = 0;
	r.origin.y = 0;
	
	r.size.width = screenSize.width;
	r.size.height = screenSize.height / 2;
	
	return r;
};

const SimpleShiftItActionBlock shiftItBottom = ^NSRect(NSRect windowRect,NSSize screenSize) {
	NSRect r;
	
	r.origin.x = 0;
	r.origin.y = screenSize.height / 2;
	
	r.size.width = screenSize.width;
	r.size.height = screenSize.height / 2;
	
	return r;
};

const SimpleShiftItActionBlock shiftItTopLeft = ^NSRect(NSRect windowRect,NSSize screenSize) {
	NSRect r;
	
	r.origin.x = 0;
	r.origin.y = 0;
	
	r.size.width = screenSize.width / 2;
	r.size.height = screenSize.height / 2;
	
	return r;
};

const SimpleShiftItActionBlock shiftItTopRight = ^NSRect(NSRect windowRect,NSSize screenSize) {
	NSRect r;
	
	r.origin.x = screenSize.width / 2;
	r.origin.y = 0;
	
	r.size.width = screenSize.width / 2;
	r.size.height = screenSize.height / 2;
	
	return r;
};

const SimpleShiftItActionBlock shiftItBottomLeft = ^NSRect(NSRect windowRect,NSSize screenSize) {
	NSRect r;
	
	r.origin.x = 0;
	r.origin.y = screenSize.height / 2;
	
	r.size.width = screenSize.width / 2;
	r.size.height = screenSize.height / 2;
	
	return r;
};

const SimpleShiftItActionBlock shiftItBottomRight = ^NSRect(NSRect windowRect,NSSize screenSize) {
	NSRect r;
	
	r.origin.x = screenSize.width / 2;
	r.origin.y = screenSize.height / 2;
	
	r.size.width = screenSize.width / 2;
	r.size.height = screenSize.height / 2;
	
	return r;
};

const SimpleShiftItActionBlock shiftItFullScreen = ^NSRect(NSRect windowRect,NSSize screenSize) {
	NSRect r;
	
	r.origin.x = 0;
	r.origin.y = 0;
	
	r.size.width = screenSize.width;
	r.size.height = screenSize.height;
	
	return r;
};

const SimpleShiftItActionBlock shiftItCenter = ^NSRect(NSRect windowRect,NSSize screenSize) {
	NSRect r;
	
	r.origin.x = (screenSize.width / 2)-(windowRect.size.width / 2);
	r.origin.y = (screenSize.height / 2)-(windowRect.size.height / 2);	
	
	r.size = windowRect.size;
	
	return r;
};

typedef enum {
	kLeftDirection = 1 << 0,
	kTopDirection = 1 << 1,
	kBottomDirection = 1 << 2,
	kRightDirection =  1 << 3
} Direction;

NSRect ShiftIt_IncreaseReduce_(NSSize screenSize, NSRect windowRect, BOOL increase) {	
	float kw = 0;
	float kh = 0;
	
	NSUserDefaults *defauts = [NSUserDefaults standardUserDefaults];

	// get the size delta settings - in pixels
	int sizeDeltaType = [defauts integerForKey:kSizeDeltaTypePrefKey];
	float coef = 0;
	switch (sizeDeltaType) {
		case kFixedSizeDeltaType:
			kw = [defauts integerForKey:kFixedSizeWidthDeltaPrefKey];
			kh = [defauts integerForKey:kFixedSizeHeightDeltaPrefKey];
			break;
		case kWindowSizeDeltaType:
			coef = [defauts floatForKey:kWindowSizeDeltaPrefKey] / 100;
			kw = windowRect.size.width * coef;
			kh = windowRect.size.height * coef;
			break;
		case kScreenSizeDeltaType:
			coef = [defauts floatForKey:kScreenSizeDeltaPrefKey] / 100;
			kw = screenSize.width * coef;
			kh = screenSize.height * coef;
			break;
		default:
			break;
	}
	
	if (kw <= 0) {
		NSLog(@"Invalid size for width delta: %f (type: %d)", kw, sizeDeltaType);
		return windowRect;
	}
	
	if (kh <= 0) {
		NSLog(@"Invalid size for height delta: %f (type: %d)", kh, sizeDeltaType);
		return windowRect;
	}
		
	int leftMargin = 0;
	int topMargin = 0;
	int bottomMargin = 0;
	int rightMargin = 0;

	// get margin settings - in pixels
	if ([defauts boolForKey:kMarginsEnabledPrefKey]) {
		leftMargin = [defauts integerForKey:kLeftMarginPrefKey];
		topMargin = [defauts integerForKey:kTopMarginPrefKey];
		bottomMargin = [defauts integerForKey:kBottomMarginPrefKey];
		rightMargin = [defauts integerForKey:kRightMarginPrefKey];
	}	
	
	// target window rect
	NSRect r = windowRect;
	// 1: increase, -1: reduce
	int inc = increase ? 1 : -1;
	// into which directio we are going to increse/reduce size
	int directions = kLeftDirection | kTopDirection | kBottomDirection | kRightDirection;
	
	// TODO: define anchor margin!
	
	if (r.origin.x <= leftMargin) {
		// do not resize to left
		directions ^= kLeftDirection;
	}
	if (r.origin.y <= topMargin) {
		// do not resize to top
		directions ^= kTopDirection;
	}
	if (r.origin.y + r.size.height >= screenSize.height - bottomMargin) {
		// do not resize to bottom
		directions ^= kBottomDirection;
	}
	if (r.origin.x + r.size.width >= screenSize.width - rightMargin) {
		// do not resize to right
		directions ^= kRightDirection;
	}
	
	// following first handle fullscreen
	// iff the window is in fullscreen than allow reducing the size with no
	// anchors
	if (!directions && !increase) {
		directions = kLeftDirection | kTopDirection | kBottomDirection | kRightDirection;
	}
	
	// max horizotal resize at a time is kw, so in case we do resize both
	// directions at the same time we do half to each
	int khorz = inc * kw;
	if (directions & kLeftDirection 
		&& directions & kRightDirection) {
		khorz /= 2;
	}
	
	// max vertical resize at a time is kh, so in case we do resize both
	// directions at the same time we do half to each
	int kvert = inc * kh;
	if (directions & kTopDirection
		&& directions & kBottomDirection) {
		kvert /= 2;
	}
	
	// adjust the size accordingly into each allowed direction
	if (directions & kLeftDirection) {
		r.origin.x -= khorz; // move left
		r.size.width +=  khorz; // resize 	
	}
	if (directions & kTopDirection) {
		r.origin.y -= kvert; // move up
		r.size.height += kvert; // resize			
	}
	if (directions & kBottomDirection) {
		r.size.height += kvert; // resize
	}
	if (directions & kRightDirection) {
		r.size.width += khorz; // resize			
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

const SimpleShiftItActionBlock shiftItIncrease = ^NSRect(NSRect windowRect,NSSize screenSize) {
	return ShiftIt_IncreaseReduce_(screenSize, windowRect, YES);
};

const SimpleShiftItActionBlock shiftItReduce = ^NSRect(NSRect windowRect,NSSize screenSize) {
	return ShiftIt_IncreaseReduce_(screenSize, windowRect, NO);
};

@implementation ToggleZoomShiftItAction

- (BOOL) execute:(id<WindowContext>)windowContext error:(NSError **)error {
    FMTAssertNotNil(windowContext);
    FMTAssertNotNil(error);
    
    NSError *cause = nil;
    SIWindow *window = nil;
    
    if(![windowContext getFocusedWindow:&window error:&cause]) {
        *error = SICreateErrorWithCause(kShiftItActionFaiureErrorCode, 
                                        cause,
                                        @"Unable to get active window");
        return NO;
    }

    if(![windowContext toggleZoomOnWindow:window error:error]) {
        return NO;
    }
    
    return YES;
}

@end

@implementation ToggleFullScreenShiftItAction

- (BOOL) execute:(id<WindowContext>)windowContext error:(NSError **)error {
    FMTAssertNotNil(windowContext);
    FMTAssertNotNil(error);
    
    NSError *cause = nil;
    SIWindow *window = nil;
    
    if(![windowContext getFocusedWindow:&window error:&cause]) {
        *error = SICreateErrorWithCause(kShiftItActionFaiureErrorCode, 
                                        cause,
                                        @"Unable to get active window");
        return NO;
    }
    
    // TODO: escape from fullscreen
    if(![windowContext toggleFullScreenOnWindow:window error:error]) {
        return NO;
    }
    
    return YES;
}

@end
