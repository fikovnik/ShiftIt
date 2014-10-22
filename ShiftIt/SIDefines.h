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

// FCE prototypes
extern short GetMBarHeight(void);

extern NSString *const SIErrorDomain;
extern NSInteger const kShiftItManagerFailureErrorCode;
// TODO: change this to be the AX error specific
extern NSInteger const kWindowManagerFailureErrorCode;
extern NSInteger const kShiftItActionFailureErrorCode;

extern NSString *const kMarginsEnabledPrefKey;
extern NSString *const kLeftMarginPrefKey;
extern NSString *const kTopMarginPrefKey;
extern NSString *const kBottomMarginPrefKey;
extern NSString *const kRightMarginPrefKey;

#define POINT_STR(point) FMTStr(@"[%.1f %.1f]", (point).x, (point).y)
#define SIZE_STR(size) FMTStr(@"[%.1f x %.1f]", (size).width, (size).height)
#define RECT_STR(rect) FMTStr(@"[%.1f %.1f] [%.1f %.1f] [%.1f x %.1f]", (rect).origin.x, (rect).origin.y, (rect).origin.x+(rect).size.width, (rect).origin.y+(rect).size.height, (rect).size.width, (rect).size.height)
#define COCOA_TO_SCREEN_COORDINATES(rect) (rect).origin.y = [[NSScreen primaryScreen] frame].size.height - (rect).size.height - (rect).origin.y

#define SICreateError(errorCode, fmt, ...) FMTCreateError(SIErrorDomain, errorCode, fmt, ##__VA_ARGS__)
#define SICreateErrorWithCause(errorCode, cause, fmt, ...) FMTCreateErrorWithCause(SIErrorDomain, errorCode, cause, fmt, ##__VA_ARGS__)

static inline NSRect SIGCToScreenOrigin(NSRect rect, SIScreen *screen) {
    NSRect r = rect;
    r.origin.x -= [screen visibleRect].origin.x;
    r.origin.y -= [screen visibleRect].origin.y;
    return r;
}

static inline NSRect SIScreenToGCOrigin(NSRect rect, SIScreen *screen) {
    NSRect r = rect;
    r.origin.x += [screen visibleRect].origin.x;
    r.origin.y += [screen visibleRect].origin.y;
    return r;
}

// TODO: move to FMT
static inline double SIDistanceBetweenPoints(NSPoint r, NSPoint s) {
    return sqrt((r.x-s.x)*(r.x-s.x) +(r.y-s.y)*(r.y-s.y));
}

// TODO: move to FMT
static inline double SIArea(NSSize s) {
    return s.width * s.height;
}

extern void GetAnchorMargin(int *leftMargin, int *topMargin, int *bottomMargin, int *rightMargin);