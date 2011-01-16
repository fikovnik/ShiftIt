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

#import <Cocoa/Cocoa.h>
#import "ShiftItAction.h"

@interface WindowShiftAction : NSObject<ShiftItActionDelegate> {
 @private
	NSString *exprX_;
	NSString *exprY_;
	NSString *exprWidth_;
	NSString *exprHeight_;
}

+ (WindowShiftAction *)windowShiftActionFromExpressionForX:(NSString *)exprX 
														 y:(NSString *)exprY 
													 width:(NSString *)exprWidth 
													height:(NSString *)exprHeight
													 error:(NSError **)error;

@end
