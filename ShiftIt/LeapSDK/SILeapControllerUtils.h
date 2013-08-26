//
//  SILeapControllerUtils.h
//  ShiftIt
//
//  Created by myeyesareblind on 8/24/13.
//
//

#ifndef ShiftIt_SILeapControllerUtils_h
#define ShiftIt_SILeapControllerUtils_h
#import "Leap.h"

typedef enum {
    SwipeGesture_Direction_Right,
    SwipeGesture_Direction_BottomRight,
    SwipeGesture_Direction_Bottom,
    SwipeGesture_Direction_BottomLeft,
    SwipeGesture_Direction_Left, /// 4
    SwipeGesture_Direction_TopLeft,
    SwipeGesture_Direction_Top,
    SwipeGesture_Direction_TopRight /// 7
} SwipeGesture_Direction;

const float M_PI_8 = (float) M_PI_4 / 2;

__attribute__((const))
static inline
SwipeGesture_Direction
swipeGesuteDirectionFromVector(Leap::Vector inVector) {
    float angle = atan2f(inVector.y, inVector.x);
    
    SwipeGesture_Direction returnDirection;
    if (angle < -7 * M_PI_8) {
        returnDirection = SwipeGesture_Direction_Right;
    }
    else if (angle < - 5 * M_PI_8) {
        returnDirection = SwipeGesture_Direction_TopRight;
    }
    else if (angle < -3 * M_PI_8) {
        returnDirection = SwipeGesture_Direction_Top;
    }
    else if (angle < -1 * M_PI_8) {
        returnDirection = SwipeGesture_Direction_TopLeft;
    }
    else if (angle < M_PI_8) {
        returnDirection = SwipeGesture_Direction_Left;
    }
    else if (angle < 3 * M_PI_8) {
        returnDirection = SwipeGesture_Direction_BottomLeft;
    }
    else if (angle < 5 * M_PI_8) {
        returnDirection = SwipeGesture_Direction_Bottom;
    }
    else if (angle < 7 * M_PI_8){
        returnDirection = SwipeGesture_Direction_BottomRight;
    }
    else {
        returnDirection = SwipeGesture_Direction_Right;
    }
    return returnDirection;
}

#endif
