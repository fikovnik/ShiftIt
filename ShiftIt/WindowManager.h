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


#import <Foundation/Foundation.h>
#import "CGSPrivate.h"

/**
 * This unit provides support for sizing application using Apple accessibiity API
 *
 */

typedef AXUIElementRef AXWindowRef;

@interface Screen : NSObject {
 @private
	NSRect visibleFrame_;
	NSRect screenFrame_;
	BOOL primary_;
}

@property (readonly) NSSize size;
@property (readonly) BOOL primary;

@end

@interface Window : NSObject {
 @private	
	AXWindowRef ref_;
	CGSWindow wid_;
	NSRect rect_;
	Screen *screen_;
}

@property (readonly) NSPoint origin;
@property (readonly) NSRect frame;
@property (readonly) NSSize size;
@property (readonly) Screen *screen;

@end

@interface WindowManager : NSObject {
 @private
    AXUIElementRef axSystemWideElement_;
	CGSConnection cgsconn_;
	
	int menuBarHeight_;
}

//- (void) startShiftsRecording;
//- (void) finishShiftsRecording;

- (void) focusedWindow:(Window **)window error:(NSError **)error;

- (void) moveWindow:(Window *)window origin:(NSPoint)origin error:(NSError **)error;
- (void) resizeWindow:(Window *)window size:(NSSize)size error:(NSError **)error;
- (void) shiftWindow:(Window *)window origin:(NSPoint)origin size:(NSSize)size error:(NSError **)error;

//- (void) focusWindow:(Window *)window relativeTo:(Window *)relativeWindow direction:(Direction)direction;
//- (void) focusWindow:(Window *)window error:(NSError **)error;

//- (void) switchScreen:(Window *)window direction:(Direction)direction flipOver:(BOOL)flip error:(NSError **)error;
//- (void) switchScreen:(Window *)window screen:(Screen *)screen error:(NSError **)error;

//- (void) switchWorkspace:(Window *)window direction:(Direction)direction flipOver:(BOOL)flip error:(NSError **)error;
- (void) switchWorkspace:(Window *)window row:(NSInteger)row col:(NSInteger)col error:(NSError **)error;

@end
