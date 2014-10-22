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
#import <Foundation/Foundation.h>

typedef struct FMTVect {
      CGFloat x;
      CGFloat y;
} FMTVect;

typedef enum {
    kLeftDirection = 1 << 0,
    kTopDirection = 1 << 1,
    kBottomDirection = 1 << 2,
    kRightDirection = 1 << 3
} FMTDirection;


FMTVect FMTMakeVect(CGFloat x1, CGFloat y1, CGFloat x2, CGFloat y2);

FMTVect FMTMakeVectWithDirection(CGFloat x, CGFloat y, FMTDirection direction);

FMTVect FMTMakePerpendicularVect(FMTVect v);

CGFloat FMTDotVect(FMTVect u, FMTVect v);

CGFloat FMTAbsVect(FMTVect v);

CGFloat FMTAngleBetweenVects(FMTVect u, FMTVect v);

FMTDirection FMTDirectionBetweenVects(FMTVect u, FMTVect v);

CGFloat FMTPointDistanceToLine(NSPoint a, NSPoint b, NSPoint p);

BOOL FMTIsRectInDirection(NSRect a, NSRect b, FMTDirection direction);