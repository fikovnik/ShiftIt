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

#define ERROR_BAR_X 5.0
#define ERROR_BAR_Y 40.0
// This deals with 2 issues:
// 1) Resizing of certain windows will not always be exactly what you asked for(Terminal)
// 2) There may be some rounding errors with the floats and converting from floats to pixels

#import <Foundation/Foundation.h>

NSRect ShiftIt_Left(NSSize screenSize, NSRect windowRect);
NSRect ShiftIt_Right(NSSize screenSize, NSRect windowRect);
NSRect ShiftIt_Top(NSSize screenSize, NSRect windowRect);
NSRect ShiftIt_Bottom(NSSize screenSize, NSRect windowRect);
NSRect ShiftIt_Left_Two_Thirds(NSSize screenSize, NSRect windowRect);
NSRect ShiftIt_Right_One_Third(NSSize screenSize, NSRect windowRect);
NSRect ShiftIt_TopLeft(NSSize screenSize, NSRect windowRect);
NSRect ShiftIt_TopRight(NSSize screenSize, NSRect windowRect);
NSRect ShiftIt_BottomLeft(NSSize screenSize, NSRect windowRect);
NSRect ShiftIt_BottomRight(NSSize screenSize, NSRect windowRect);
NSRect ShiftIt_FullScreen(NSSize screenSize, NSRect windowRect);
NSRect ShiftIt_Center(NSSize screenSize, NSRect windowRect);

float SizeIt(float part, float full, float errorBar);
