/*
 Copyright (c) 2010-2011 Filip Krikava

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 */

#import "FMTGeometry.h"
#import "FMTDefines.h"

FMTVect FMTMakeVect(CGFloat x1, CGFloat y1, CGFloat x2, CGFloat y2) {
    FMTVect v = {x2 - x1, y2 - y1};
    return v;
}

FMTVect FMTMakeVectWithDirection(CGFloat x, CGFloat y, FMTDirection direction) {
    switch (direction) {
        case kLeftDirection:
            return FMTMakeVect(x, y, x-1, y);
        case kTopDirection:
            return FMTMakeVect(x, y, x, y+1);
        case kBottomDirection:
            return FMTMakeVect(x, y, x, y-1);
        case kRightDirection:
            return FMTMakeVect(x, y, x+1, y);
        default:
            FMTAssert(NO, @"Unknown direction %d", direction);
    }
}

FMTVect FMTMakePerpendicularVect(FMTVect v) {
    FMTVect n = {v.y, - v.x};
    return n;
}

CGFloat FMTDotVect(FMTVect u, FMTVect v) {
    return u.x * v.x + u.y * v.y;
}

CGFloat FMTAbsVect(FMTVect v) {
    return (CGFloat) sqrt(v.x * v.x + v.y * v.y);
}

CGFloat FMTAngleBetweenVects(FMTVect u, FMTVect v) {
    return (CGFloat) (acos(FMTDotVect(u, v) / FMTAbsVect(u) / FMTAbsVect(v)) * 180 / M_PI);
}

FMTDirection FMTDirectionBetweenVects(FMTVect u, FMTVect v) {
    switch ((int)FMTAngleBetweenVects(u, v)) {
        case 0:
            return kTopDirection;
        case 90:
            return kRightDirection;
        case 180:
            return kBottomDirection;
        case 270:
            return kLeftDirection;
        default: 
            return kLeftDirection;
    }
}

CGFloat FMTPointDistanceToLine(NSPoint a, NSPoint b, NSPoint p) {
    FMTVect v = FMTMakeVect(a.x, a.y, b.x, b.y);
    FMTVect n = FMTMakePerpendicularVect(v);
    FMTVect r = FMTMakeVect(p.x, p.y, a.x, a.y);

    return (CGFloat) fabs(FMTDotVect(r,n)/FMTAbsVect(n));
}

BOOL FMTIsRectInDirection(NSRect a, NSRect b, FMTDirection direction) {
    switch (direction) {
        case kLeftDirection:
            return a.origin.x < b.origin.x;
        case kTopDirection:
            return a.origin.y < b.origin.y;
        case kBottomDirection:
            return a.origin.y >= b.origin.y + b.size.height;
        case kRightDirection:
            return a.origin.x >= b.origin.x + b.size.width;
        default:
            FMTAssert(NO, @"Unknown direction %d", direction);
    }
}