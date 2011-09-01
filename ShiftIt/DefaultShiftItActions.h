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

#import <Foundation/Foundation.h>
#import "SimpleShiftItAction.h"

const extern SimpleShiftItActionBlock shiftItLeft;
const extern SimpleShiftItActionBlock shiftItRight;
const extern SimpleShiftItActionBlock shiftItTop;
const extern SimpleShiftItActionBlock shiftItBottom;
const extern SimpleShiftItActionBlock shiftItTopLeft;
const extern SimpleShiftItActionBlock shiftItTopRight;
const extern SimpleShiftItActionBlock shiftItBottomLeft;
const extern SimpleShiftItActionBlock shiftItBottomRight;
const extern SimpleShiftItActionBlock shiftItFullScreen;
const extern SimpleShiftItActionBlock shiftItCenter;
const extern SimpleShiftItActionBlock shiftItIncrease;
const extern SimpleShiftItActionBlock shiftItReduce;

@interface ToggleZoomShiftItAction : AbstractShiftItAction
@end

@interface ToggleFullScreenShiftItAction : AbstractShiftItAction
@end