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

@interface SIScreen : NSObject

@property (readonly) NSSize size;
@property (readonly) NSRect visibleRect;
@property (readonly) NSRect rect;
@property (readonly) BOOL primary;

+ (SIScreen *) primaryScreen;
+ (NSArray *) screens;
+ (SIScreen *) screenFromNSScreen:(NSScreen *)screen;
+ (SIScreen *) screenForWindowGeometry:(NSRect)geometry;

- (id) initWithNSScreen:(NSScreen *)screen;
- (SIScreen *) previousScreen;
- (SIScreen *) nextScreen;
- (BOOL)isEqualToScreen:(SIScreen *)screen;

@end
