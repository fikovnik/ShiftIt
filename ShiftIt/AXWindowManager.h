/*
 ShiftIt: Resize windows with Hotkeys
 Copyright (C) 2010  Aravind
 
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

// from whatever reason this attribute is missing in the AXAttributeConstants.h
#define kAXFullScreenAttribute  CFSTR("AXFullScreen")

@interface AXWindowManager : NSObject

+ (AXWindowManager *) sharedAXWindowManager;

- (BOOL) getFocusedWindow:(AXUIElementRef *)windowRef error:(NSError **)error;

- (void) freeWindow:(AXUIElementRef)windowRef;

- (BOOL) setPosition:(NSPoint)position window:(AXUIElementRef)windowRef error:(NSError **)error;

- (BOOL) setSize:(NSSize)size window:(AXUIElementRef)windowRef error:(NSError **)error;

- (BOOL) getGeometry:(NSRect *)rect window:(AXUIElementRef)windowRef error:(NSError **)error;

- (BOOL) getDrawersGeometry:(NSRect *)rect window:(AXUIElementRef)windowRef error:(NSError **)error;

- (BOOL) getFullScreenMode:(BOOL *)fullScreen window:(AXUIElementRef)windowRef error:(NSError **)error;

- (BOOL) getPosition:(NSPoint *)position element:(AXUIElementRef)element error:(NSError **)error;

- (BOOL) getSize:(NSSize *)size element:(AXUIElementRef)element error:(NSError **)error;


@end
