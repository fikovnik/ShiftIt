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

typedef void (*ShiftItFunctionRef)(NSPoint *sceenPosition, NSSize *screenSize, NSPoint *windowPosition, NSSize *windowSize); 

@interface ShiftItAction : NSObject {
 @private
	NSString *identifier_;
	NSString *label_;
	NSInteger uiTag_;
	ShiftItFunctionRef action_;
}

@property (readonly) NSString *identifier;
@property (readonly) NSString *label;
@property (readonly) NSInteger uiTag;
@property (readonly) ShiftItFunctionRef action;

- (id) initWithIdentifier:(NSString *)identifier label:(NSString *)label uiTag:(NSInteger)uiTag action:(ShiftItFunctionRef)action;

@end
