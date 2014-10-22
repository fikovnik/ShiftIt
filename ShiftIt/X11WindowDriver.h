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

// make sure this does not collide with the Cursor from Carbon/Cocoa
#define Cursor X11Cursor
#import <X11/Xlib.h>
#import <X11/Xatom.h>
#import <X11/Xutil.h>
#undef Cursor

#import <Foundation/Foundation.h>
#import "SIWindowDriver.h"

@interface X11WindowDriver : NSObject<SIWindowDriver> {

}

- (id)initWithError:(NSError **)error;

@end
