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

#define ARGS_NOT_NULL 	FMTAssertNotNil(sceenPosition); \
	FMTAssertNotNil(screenSize); \
	FMTAssertNotNil(windowPosition); \
	FMTAssertNotNil(windowSize);


void ShiftIt_Left(NSPoint *sceenPosition, NSSize *screenSize, NSPoint *windowPosition, NSSize *windowSize) {
	ARGS_NOT_NULL;
	
	windowPosition->x = sceenPosition->x;
	windowPosition->y = sceenPosition->y;
	
	windowSize->width = screenSize->width / 2;
	windowSize->height = screenSize->height;
}

void ShiftIt_Right(NSPoint *sceenPosition, NSSize *screenSize, NSPoint *windowPosition, NSSize *windowSize) {
	ARGS_NOT_NULL;
	
	windowPosition->x = sceenPosition->x + screenSize->width/2;
	windowPosition->y = sceenPosition->y;
	
	windowSize->width = screenSize->width / 2;
	windowSize->height = screenSize->height;
}

void ShiftIt_Top(NSPoint *sceenPosition, NSSize *screenSize, NSPoint *windowPosition, NSSize *windowSize) {
	ARGS_NOT_NULL;
	
	windowPosition->x = sceenPosition->x;
	windowPosition->y = sceenPosition->y;
	
	windowSize->width = screenSize->width;
	windowSize->height = screenSize->height / 2;
}

void ShiftIt_Bottom(NSPoint *sceenPosition, NSSize *screenSize, NSPoint *windowPosition, NSSize *windowSize) {
	ARGS_NOT_NULL;
	
	windowPosition->x = sceenPosition->x;
	windowPosition->y = sceenPosition->y + screenSize->height / 2;
	
	windowSize->width = screenSize->width / 2;
	windowSize->height = screenSize->height;
}

void ShiftIt_TopLeft(NSPoint *sceenPosition, NSSize *screenSize, NSPoint *windowPosition, NSSize *windowSize) {
	ARGS_NOT_NULL;
	
	windowPosition->x = sceenPosition->x;
	windowPosition->y = sceenPosition->y;
	
	windowSize->width = screenSize->width / 2;
	windowSize->height = screenSize->height / 2;
}

void ShiftIt_TopRight(NSPoint *sceenPosition, NSSize *screenSize, NSPoint *windowPosition, NSSize *windowSize) {
	ARGS_NOT_NULL;
	
	windowPosition->x = sceenPosition->x + screenSize->width / 2;
	windowPosition->y = sceenPosition->y;
	
	windowSize->width = screenSize->width / 2;
	windowSize->height = screenSize->height / 2;
}

void ShiftIt_BottomLeft(NSPoint *sceenPosition, NSSize *screenSize, NSPoint *windowPosition, NSSize *windowSize) {
	ARGS_NOT_NULL;
	
	windowPosition->x = sceenPosition->x;
	windowPosition->y = sceenPosition->y + screenSize->height / 2;
	
	windowSize->width = screenSize->width / 2;
	windowSize->height = screenSize->height / 2;
}

void ShiftIt_BottomRight(NSPoint *sceenPosition, NSSize *screenSize, NSPoint *windowPosition, NSSize *windowSize) {
	ARGS_NOT_NULL;
	
	windowPosition->x = sceenPosition->x + screenSize->width / 2;
	windowPosition->y = sceenPosition->y + screenSize->height / 2;
	
	windowSize->width = screenSize->width / 2;
	windowSize->height = screenSize->height / 2;
}

void ShiftIt_FullScreen(NSPoint *sceenPosition, NSSize *screenSize, NSPoint *windowPosition, NSSize *windowSize) {
	ARGS_NOT_NULL;
	
	windowPosition->x = sceenPosition->x;
	windowPosition->y = sceenPosition->y;
	
	windowSize->width = screenSize->width;
	windowSize->height = screenSize->height;
}

void ShiftIt_Center(NSPoint *sceenPosition, NSSize *screenSize, NSPoint *windowPosition, NSSize *windowSize) {
	ARGS_NOT_NULL;
	
	windowPosition->x = sceenPosition->x + (screenSize->width/2)-(windowSize->width/2);
	windowPosition->y = sceenPosition->y + (screenSize->height/2)-(windowSize->height/2);	
}

