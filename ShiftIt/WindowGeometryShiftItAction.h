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

typedef struct _AnchoredRect {
  NSRect rect;
  int anchor;
} AnchoredRect;

inline static AnchoredRect MakeAnchoredRect(NSRect rect, int anchor) {
    AnchoredRect r = { rect, anchor };
    return r;
}

@interface AbstractWindowGeometryShiftItAction : NSObject<SIActionDelegate>

- (AnchoredRect) shiftWindowRect:(NSRect)windowRect screenSize:(NSSize)screenSize withContext:(id<SIWindowContext>)windowContext;

@end

typedef AnchoredRect(^SimpleWindowGeometryChangeBlock)(NSRect, NSSize);

@interface WindowGeometryShiftItAction : AbstractWindowGeometryShiftItAction {
 @private
    SimpleWindowGeometryChangeBlock block_;
}

- (id) initWithBlock:(SimpleWindowGeometryChangeBlock)block;

@end
