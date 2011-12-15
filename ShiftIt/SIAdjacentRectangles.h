/*
 ShiftIt: Window Organizer for OSX
 Copyright (c) 2010-2011 Filip Krikava

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
#import "SIDefines.h"
#import "FMT/FMT.h"

@interface SIValueRect : NSObject

@property(readonly) NSRect rect;
@property(readonly) id value;

- (id)initWithRect:(NSRect)rect value:(id)value;

+ (id)rect:(NSRect)rect withValue:(id)value;

@end

@interface SIDistanceValueRect : NSObject

@property(readonly) CGFloat distance;
@property(readonly) NSRect rect;
@property(readonly) id value;

- (id)initWithDistance:(CGFloat)distance rect:(NSRect)rect value:(id)value;

@end

@interface SIAdjacentRectangles : NSObject

- (id)initWithRectValues:(NSArray *)rectValues;

- (NSArray *)rectanglesInDirection:(FMTDirection)direction fromRect:(NSRect)rect;

- (NSArray *)rectanglesInDirection:(FMTDirection)direction fromValue:(id)value;

- (NSArray *)buildDirectionalPath:(const FMTDirection *)directions fromValue:(id)value;

+ (id)adjacentRect:(NSArray *)rectValues;

@end