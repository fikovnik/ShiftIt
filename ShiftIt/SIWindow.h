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

#import "SIScreen.h"

@protocol SIWindow <NSObject>

@required

/**
 * @param geometry a pointer to a NSRect where the current geometry of a window will be stored. It can be nil in which case no information will be stored.
 * @param screen a pointer to a SIScreen where the current screen of a window will be stored. It can be nil in which case no information will be stored.
 * @param shall there be a problem obtaining the window geometry information the cause will be stored in this pointer if it is not nil.
 *
 * @returns YES on success, NO otherwise while setting the error parameter
 */
- (BOOL) getGeometry:(NSRect *)geometry screen:(SIScreen **)screen error:(NSError **)error;
- (BOOL) setGeometry:(NSRect)geometry screen:(SIScreen *)screen error:(NSError **)error;
- (BOOL) canMove:(BOOL *)flag error:(NSError **)error;
- (BOOL) canResize:(BOOL *)flag error:(NSError **)error;
- (BOOL) canZoom:(BOOL *)flag error:(NSError **)error;
- (BOOL) canEnterFullScreen:(BOOL *)flag error:(NSError **)error;

@optional
- (BOOL) getWindowRect:(NSRect *)windowRect screen:(SIScreen **)screen drawersRect:(NSRect *)drawersRect error:(NSError **)error;
- (BOOL) getFullScreen:(BOOL *)flag error:(NSError **)error;
- (BOOL) toggleFullScreen:(NSError **)error;
- (BOOL) toggleZoom:(NSError **)error;

@end