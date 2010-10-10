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

#import <Foundation/Foundation.h>

void ShiftIt_Left(NSPoint *sceenPosition, NSSize *screenSize, NSPoint *windowPosition, NSSize *windowSize);
void ShiftIt_Right(NSPoint *sceenPosition, NSSize *screenSize, NSPoint *windowPosition, NSSize *windowSize);
void ShiftIt_Top(NSPoint *sceenPosition, NSSize *screenSize, NSPoint *windowPosition, NSSize *windowSize);
void ShiftIt_Bottom(NSPoint *sceenPosition, NSSize *screenSize, NSPoint *windowPosition, NSSize *windowSize);
void ShiftIt_TopLeft(NSPoint *sceenPosition, NSSize *screenSize, NSPoint *windowPosition, NSSize *windowSize);
void ShiftIt_TopRight(NSPoint *sceenPosition, NSSize *screenSize, NSPoint *windowPosition, NSSize *windowSize);
void ShiftIt_BottomLeft(NSPoint *sceenPosition, NSSize *screenSize, NSPoint *windowPosition, NSSize *windowSize);
void ShiftIt_BottomRight(NSPoint *sceenPosition, NSSize *screenSize, NSPoint *windowPosition, NSSize *windowSize);
void ShiftIt_FullScreen(NSPoint *sceenPosition, NSSize *screenSize, NSPoint *windowPosition, NSSize *windowSize);
void ShiftIt_Center(NSPoint *sceenPosition, NSSize *screenSize, NSPoint *windowPosition, NSSize *windowSize);
