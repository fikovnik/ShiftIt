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

#import "AbstractShiftItAction.h"
#import "FMTDefines.h"

NSInteger const kShiftItActionFaiureErrorCode = 20103;

@implementation AbstractShiftItAction

@synthesize identifier = identifier_;
@synthesize label = label_;
@synthesize uiTag = uiTag_;

- (id) initWithIdentifier:(NSString *)identifier label:(NSString *)label uiTag:(NSInteger)uiTag {
	FMTAssertNotNil(identifier);
	FMTAssertNotNil(label);
	FMTAssert(uiTag > 0, @"uiTag must be greater than 0");

	if (![super init]) {
		return nil;
	}
	
	identifier_ = [identifier retain];
	label_ = [label retain];
	uiTag_ = uiTag;
	
	return self;
}

- (void) dealloc {
	[identifier_ release];
	[label_ release];
	
	[super dealloc];
}

- (BOOL) execute:(id<WindowContext>)windowContext error:(NSError **)error {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:FMTStr(@"You must override %@ in a subclass", NSStringFromSelector(_cmd))
                                 userInfo:nil];
}

@end
