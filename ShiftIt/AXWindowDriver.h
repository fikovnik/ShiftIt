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
#import "ShiftIt.h"

/**
 * In order to understand what exactly what is going on it is important
 * to understand how the graphic coordinates works in OSX. There are two
 * coordinates systems: screen (quartz core graphics) and cocoa. The
 * former one has and origin on the top left corner of the primary
 * screen (the one with a menu bar) and the coordinates grows in east
 * and south direction. The latter has origin in the bottom left corner
 * of the primary window and grows in east and north direction. The
 * overview of the cocoa coordinates is in [1].
 *
 * In this method all coordinates are translated to be the screen
 * coordinates.
 *
 * [1] http://bit.ly/aSmfae (apple official docs)
 */
@interface AXWindowDriver : NSObject<SIWindowDriver> {
 @private
    AXUIElementRef systemElementRef_;
    BOOL shouldUseDrawers_;
    BOOL converge_;
    double delayBetweenOperations_;
}

@property(assign) BOOL shouldUseDrawers;
@property(assign) BOOL converge;
@property(assign) double delayBetweenOperations;

- (id)initWithError:(NSError **)error;


@end
