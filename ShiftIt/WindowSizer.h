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


#import <Cocoa/Cocoa.h>

@interface WindowSizer : NSObject {
    AXUIElementRef	systemWideElement_;
    CFTypeRef focusedWindow_;
    NSSize screenSize_;
    NSSize screenVisibleSize_;
    NSPoint screenVisiblePosition_;
    NSPoint screenPosition_;
    NSPoint windowPosition_;
    NSSize windowSize_;
	int menuBarHeight_;
}

-(IBAction)shiftToLeftHalf:(id)sender;
-(IBAction)shiftToRightHalf:(id)sender;
-(IBAction)shiftToBottomHalf:(id)sender;
-(IBAction)shiftToTopHalf:(id)sender;
-(IBAction)shiftToTopRight:(id)sender;
-(IBAction)shiftToTopLeft:(id)sender;
-(IBAction)shiftToBottomLeft:(id)sender;
-(IBAction)shiftToBottomRight:(id)sender;
-(IBAction)fullScreen:(id)sender;
-(IBAction)shiftToCenter:(id)sender;

@end
