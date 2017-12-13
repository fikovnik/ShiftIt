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
#import "WindowGeometryShiftItAction.h"
#import "ShiftIt.h"

BOOL CloseTo(double a, double b);
BOOL rectCloseTo(NSRect a, NSRect b);

const extern SimpleWindowGeometryChangeBlock shiftItLeft;
const extern SimpleWindowGeometryChangeBlock shiftItRight;
const extern SimpleWindowGeometryChangeBlock shiftItTop;
const extern SimpleWindowGeometryChangeBlock shiftItBottom;
const extern SimpleWindowGeometryChangeBlock shiftItTopLeft;
const extern SimpleWindowGeometryChangeBlock shiftItTopRight;
const extern SimpleWindowGeometryChangeBlock shiftItBottomLeft;
const extern SimpleWindowGeometryChangeBlock shiftItBottomRight;
const extern SimpleWindowGeometryChangeBlock shiftItFullScreen;
const extern SimpleWindowGeometryChangeBlock shiftItCenter;

@interface IncreaseReduceShiftItAction : AbstractWindowGeometryShiftItAction {
 @private
    BOOL increase_;
}

- (id) initWithMode:(BOOL)increase;

@end

@interface ToggleZoomShiftItAction : NSObject<SIActionDelegate>
@end

@interface ToggleFullScreenShiftItAction : NSObject<SIActionDelegate>
@end

@interface ScreenChangeShiftItAction : NSObject<SIActionDelegate>

- (id) initWithMode:(BOOL)next;

@end
