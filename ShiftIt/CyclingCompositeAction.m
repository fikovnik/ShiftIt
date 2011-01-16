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

#import "CyclingCompositeAction.h"
#import "FMTDefines.h"

@implementation CyclingCompositeAction

- initWithActions:(NSArray *)actions {
	if (![super init]) {
		return nil;
	}
	
	FMTAssertNotNil(actions);
	FMTAssert([actions count] > 0, @"At least one action must be present");
	
	actions_ = [[NSArray arrayWithArray:actions] retain];
	current_ = 0;
	
	return self;
}

- (void) dealloc {
	[actions_ release];
	
	[super dealloc];
}

- (BOOL) executeWithWindowManager:(WindowManager *)windowManager error:(NSError **)error {
	FMTAssertNotNil(windowManager);
	
	if (current_ == [actions_ count]) {
		current_ = 0;
	}
	
	NSObject<ShiftItActionDelegate> *action = [actions_ objectAtIndex:current_];	
	current_++;
	
	return [action executeWithWindowManager:windowManager error:error];
}

@end
