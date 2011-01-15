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
#import "WindowManager.h"
#import "ShiftIt.h"
#import "FMTDefines.h"

void ShiftIt_Left(WindowManager *windowManager, NSError **error) {
	Window *focusedWindow = nil;
	NSError *localError = nil;
	
	GET_FOCUSED_WINDOW(focusedWindow, windowManager, error, localError);
	
	NSPoint origin = {0, 0};
	NSSize size = [[focusedWindow screen] size];
	
	size.width = size.width / 2;

	[windowManager shiftWindow:focusedWindow origin:origin size:size error:&localError];
	HANDLE_WM_ERROR(error, localError);	
}

//NSRect ShiftIt_Right(NSSize screenSize, NSRect windowRect) {
//	NSRect r;
//	
//	r.origin.x = screenSize.width/2;
//	r.origin.y = 0;
//	
//	r.size.width = screenSize.width / 2;
//	r.size.height = screenSize.height;
//
//	return r;
//}
//
//NSRect ShiftIt_Top(NSSize screenSize, NSRect windowRect) {
//	NSRect r;
//	
//	r.origin.x = 0;
//	r.origin.y = 0;
//	
//	r.size.width = screenSize.width;
//	r.size.height = screenSize.height / 2;
//	
//	return r;
//}
//
//NSRect ShiftIt_Bottom(NSSize screenSize, NSRect windowRect) {
//	NSRect r;
//	
//	r.origin.x = 0;
//	r.origin.y = screenSize.height / 2;
//	
//	r.size.width = screenSize.width;
//	r.size.height = screenSize.height / 2;
//	
//	return r;
//}
//
//NSRect ShiftIt_TopLeft(NSSize screenSize, NSRect windowRect) {
//	NSRect r;
//	
//	r.origin.x = 0;
//	r.origin.y = 0;
//	
//	r.size.width = screenSize.width / 2;
//	r.size.height = screenSize.height / 2;
//	
//	return r;
//}
//
//NSRect ShiftIt_TopRight(NSSize screenSize, NSRect windowRect) {
//	NSRect r;
//	
//	r.origin.x = screenSize.width / 2;
//	r.origin.y = 0;
//	
//	r.size.width = screenSize.width / 2;
//	r.size.height = screenSize.height / 2;
//	
//	return r;
//}
//
//NSRect ShiftIt_BottomLeft(NSSize screenSize, NSRect windowRect) {
//	NSRect r;
//	
//	r.origin.x = 0;
//	r.origin.y = screenSize.height / 2;
//	
//	r.size.width = screenSize.width / 2;
//	r.size.height = screenSize.height / 2;
//	
//	return r;
//}
//
//NSRect ShiftIt_BottomRight(NSSize screenSize, NSRect windowRect) {
//	NSRect r;
//	
//	r.origin.x = screenSize.width / 2;
//	r.origin.y = screenSize.height / 2;
//	
//	r.size.width = screenSize.width / 2;
//	r.size.height = screenSize.height / 2;
//	
//	return r;
//}
//
//NSRect ShiftIt_FullScreen(NSSize screenSize, NSRect windowRect) {
//	NSRect r;
//	
//	r.origin.x = 0;
//	r.origin.y = 0;
//	
//	r.size.width = screenSize.width;
//	r.size.height = screenSize.height;
//	
//	return r;
//}
//
//NSRect ShiftIt_Center(NSSize screenSize, NSRect windowRect) {
//	NSRect r;
//	
//	r.origin.x = (screenSize.width / 2)-(windowRect.size.width / 2);
//	r.origin.y = (screenSize.height / 2)-(windowRect.size.height / 2);	
//	
//	r.size = windowRect.size;
//	
//	return r;
//}
