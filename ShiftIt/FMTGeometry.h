//
//  Created by krikava on 14/12/11.
//
// To change the template use AppCode | Preferences | File Templates.
//


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