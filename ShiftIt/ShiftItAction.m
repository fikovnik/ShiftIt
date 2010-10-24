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

#import "ShiftItAction.h"
#import "FMTDefines.h"

@implementation ShiftItAction

@synthesize identifier = identifier_;
@synthesize label = label_;
@synthesize uiTag = uiTag_;
@synthesize action = action_;

- (id) initWithIdentifier:(NSString *)identifier label:(NSString *)label uiTag:(NSInteger)uiTag action:(ShiftItFunctionRef)action {
	FMTAssertNotNil(identifier);
	FMTAssertNotNil(label);
	FMTAssert(uiTag > 0, @"uiTag must be greater than 0");
	FMTAssertNotNil(action);

	if (![super init]) {
		return nil;
	}
	
	identifier_ = [identifier retain];
	label_ = [label retain];
	uiTag_ = uiTag;
	action_ = action;
	
	return self;
}

- (void) dealloc {
	[identifier_ release];
	[label_ release];
	
	[super dealloc];
}

@end
