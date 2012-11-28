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

#import <Carbon/Carbon.h>
#import "WindowGeometryShiftItAction.h"

@implementation AbstractWindowGeometryShiftItAction

- (BOOL) execute:(id<SIWindowContext>)windowContext error:(NSError **)error {
    FMTAssertNotNil(windowContext);
    FMTAssertNotNil(error);
    
    NSError *cause = nil;
    id<SIWindow> window = nil;
    BOOL flag = NO;

    if(![windowContext getFocusedWindow:&window error:&cause]) {
        *error = SICreateErrorWithCause(kShiftItActionFailureErrorCode,
                                        cause,
                                        @"Unable to get active window");
        return NO;
    }

    if ([window respondsToSelector:@selector(getFullScreen:error:)]) {
        if (![window getFullScreen:&flag error:&cause]) {
            *error = SICreateErrorWithCause(kShiftItActionFailureErrorCode,
                                            cause,
                                            @"Unable to get window fullScreen state");
        }
        if (flag) {
            *error = SICreateError(kShiftItActionFailureErrorCode, @"Windows in fullscreen are not supported");
            return NO;
        }
    }

    NSRect currentGeometry;
    SIScreen *screen;
    if (![window getGeometry:&currentGeometry screen:&screen error:&cause]) {
        *error = SICreateErrorWithCause(kShiftItActionFailureErrorCode,
                                        cause,
                                        @"Unable to get window geometry");
        return NO;        
    }

    FMTLogInfo(@"Current window geometry: %@", RECT_STR(currentGeometry));

    NSSize screenSize = [screen size];
    AnchoredRect anchoredRect = [self shiftWindowRect:currentGeometry screenSize:screenSize withContext:windowContext];
    NSRect geometry = anchoredRect.rect;

    if (!NSEqualPoints(currentGeometry.origin, geometry.origin)) {
        if (![window canMove:&flag error:&cause]) {
            *error = SICreateErrorWithCause(kShiftItActionFailureErrorCode,
                                            cause,
                                            @"Unable to find out if window is moveable");
            return NO;
        }
        if (!flag) {
            *error = SICreateError(kShiftItActionFailureErrorCode, @"Window is not moveable");
            return NO;
        }
    }

    if (!NSEqualSizes(currentGeometry.size, geometry.size)) {
        if (![window canResize:&flag error:&cause]) {
            *error = SICreateErrorWithCause(kShiftItActionFailureErrorCode,
                                            cause,
                                            @"Unable to find out if window is resizeable");
            return NO;
        }
        if (!flag) {
            if (anchoredRect.anchor & kRightDirection) {
                geometry.origin.x += geometry.size.width - currentGeometry.size.width;
            }

            if (anchoredRect.anchor & kBottomDirection) {
                geometry.origin.y += geometry.size.height - currentGeometry.size.height;
            }

            geometry.size.width = currentGeometry.size.width;
            geometry.size.height = currentGeometry.size.height;

            FMTLogInfo(@"Window seems not to be resizeable, will try to move it at least.\n "
                        "Readjusting the geometry with respect to anchor %d: %@",
                            anchoredRect.anchor,
                            RECT_STR(geometry));
        }
    }

    FMTLogInfo(@"New window geometry: %@", RECT_STR(geometry));

    if (![window setGeometry:geometry screen:screen error:&cause]) {
        *error = SICreateErrorWithCause(kShiftItActionFailureErrorCode,
                                        cause,
                                        @"Unable to adjust window geometry to %@", RECT_STR(geometry));
        return NO;
    }

    if (![windowContext anchorWindow:window to:anchoredRect.anchor error:&cause]) {
        *error = SICreateErrorWithCause(kShiftItActionFailureErrorCode,
                                        cause,
                                        @"Unable to anchor window");
        return NO;
    }
    
    // TODO: make sure window is always visible
    
    return YES;
}

- (AnchoredRect) shiftWindowRect:(NSRect)windowRect screenSize:(NSSize)screenSize withContext:(id<SIWindowContext>)windowContext {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:FMTStr(@"You must override %@ in a subclass", NSStringFromSelector(_cmd))
                                 userInfo:nil];
}

@end

@implementation WindowGeometryShiftItAction

- (id) initWithBlock:(SimpleWindowGeometryChangeBlock)block {
    FMTAssertNotNil(block);
    
    if (![super init]) {
        return nil;
    }
    
    block_ = block;
    
    return self;
}

- (AnchoredRect)shiftWindowRect:(NSRect)windowRect screenSize:(NSSize)screenSize withContext:(id<SIWindowContext>)windowContext {
    return block_(windowRect, screenSize);
}

@end