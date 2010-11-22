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

/**
 * This unit provides support for sizing application using Apple accessibiity API
 *
 */

@class ShiftItAction;

@interface WindowSizer : NSObject {
 @private
    AXUIElementRef axSystemWideElement_;
	
	int menuBarHeight_;
	NSString *lastActionExecuted;
}

+ (WindowSizer *) sharedWindowSize;

- (void) shiftFocusedWindowUsing:(ShiftItAction *)action error:(NSError **)error;
//- (void) reduceWindowFivePercent:(void *)window winRect:(NSRect)windowRect error:(NSError **)error;
- (NSScreen *)chooseScreenForWindow_:(NSRect)windowRect;
- (NSScreen *)nextScreenForAction:(ShiftItAction*)action window:(NSRect)windowRect;

@property (nonatomic, retain) NSString *lastActionExecuted;

@end
