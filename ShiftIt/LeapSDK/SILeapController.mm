//
//  SILeapController.m
//  ShiftIt
//
//  Created by myeyesareblind on 8/24/13.
//
//

#import "SILeapController.h"
#import "Leap.h"
#import "SILeapControllerUtils.h"

class SILeapListener;

using namespace Leap;

@protocol SILeapListenerDelegate <NSObject>
- (void)leapListenerDidFindCircleGesture:(SILeapListener*)leapListener;
- (void)leapListener:(SILeapListener*)leapListener didFindSwipeGestureWithDirection:(SwipeGesture_Direction)swipeDirection;
@end


class SILeapListener : public Leap::Listener {
    id<SILeapListenerDelegate> _delegate;
    CFTimeInterval             _lastGestureTime;
public:
    SILeapListener():
    _delegate(nil),
    _lastGestureTime(CFAbsoluteTimeGetCurrent()){
    }
    
    void setDelegate(id<SILeapListenerDelegate> delegate){
        _delegate = delegate;
    }
    id<SILeapListenerDelegate> getDelegate() {
        return _delegate;
    }
    
    virtual void onInit(const Leap::Controller&);
    virtual void onFrame(const Leap::Controller&);
};


void
SILeapListener::onInit(const Leap::Controller& controller) {
}


const float SWIPE_MINIMUM_TRIGGER_DISTANCE        = 50.0f;
const float GESTURE_MINIMUM_DELAY_BETWEEN_ACTIONS = 1.0f;

void
SILeapListener::onFrame(const Leap::Controller& controller) {
    const Frame         frame    = controller.frame();
    const GestureList   gestures = frame.gestures();
    
    CFTimeInterval currentTime = CFAbsoluteTimeGetCurrent();
    if (currentTime - _lastGestureTime < GESTURE_MINIMUM_DELAY_BETWEEN_ACTIONS) {
        return ;
    }
    for (GestureList::const_iterator iterator = gestures.begin(); iterator != gestures.end(); ++iterator) {
        Gesture singleGesture = *iterator;
        if (! singleGesture.isValid()) {
            continue ;
        }
        
        if (singleGesture.type() == Gesture::TYPE_CIRCLE) {
            CircleGesture circleGesture = (CircleGesture) singleGesture;
            
            if (circleGesture.state() == Gesture::STATE_STOP
                && circleGesture.progress() > 1) {
                circleGesture.invalid();
                [_delegate leapListenerDidFindCircleGesture:this];
                
                _lastGestureTime = currentTime;
            }
            
            continue ;
        }
        
        if (singleGesture.type() == Gesture::TYPE_SWIPE) {
            SwipeGesture swipeGesture = (SwipeGesture) singleGesture;
            
            if (swipeGesture.state() == Gesture::STATE_STOP) {
                Vector distanceVector         = swipeGesture.startPosition() - swipeGesture.position();
                float  distance = distanceVector.magnitude();
                if (distance > SWIPE_MINIMUM_TRIGGER_DISTANCE) {
                    SwipeGesture_Direction direction = swipeGesuteDirectionFromVector(distanceVector);
                    [_delegate leapListener:this didFindSwipeGestureWithDirection:direction];
                    _lastGestureTime = currentTime;
                }
            }
        }
    }
}


@interface SILeapController () <SILeapListenerDelegate> {
    SILeapListener*      leapListener;
    Leap::Controller*    leapController;
}
@end


@implementation SILeapController
@synthesize gestureHandleBlock;


-(id) init {
    self = [super init];
    if (!self)
        return nil;
    leapController  = new Leap::Controller();
    leapController->enableGesture(Gesture::TYPE_SWIPE);
    leapController->enableGesture(Gesture::TYPE_CIRCLE);
    leapController->setPolicyFlags(Controller::POLICY_BACKGROUND_FRAMES);
    
    leapListener    = new SILeapListener();
    leapListener->setDelegate(self);
    
    leapController->addListener(*leapListener);
    return self;
}


- (void)leapListenerDidFindCircleGesture:(SILeapListener*)leapListener {
    dispatch_async(dispatch_get_main_queue(), ^{
        gestureHandleBlock(@"nextscreen");
    });
}


- (void)leapListener:(SILeapListener*)leapListener didFindSwipeGestureWithDirection:(SwipeGesture_Direction)swipeDirection {
    NSString* actionIdentifier = nil;
    switch (swipeDirection) {
        case SwipeGesture_Direction_Bottom:
            actionIdentifier = @"bottom";
            break;
        case SwipeGesture_Direction_BottomLeft:
            actionIdentifier = @"bl";
            break;
        case SwipeGesture_Direction_BottomRight:
            actionIdentifier = @"br";
            break;
        case SwipeGesture_Direction_Left:
            actionIdentifier = @"left";
            break;
        case SwipeGesture_Direction_Right:
            actionIdentifier = @"right";
            break;
        case SwipeGesture_Direction_TopLeft:
            actionIdentifier = @"tl";
            break;
        case SwipeGesture_Direction_Top:
            actionIdentifier = @"top";
            break;
        case SwipeGesture_Direction_TopRight:
            actionIdentifier = @"tr";
            break;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        gestureHandleBlock(actionIdentifier);
    });
}


-(void)dealloc {
    delete leapListener;
    delete leapController;
    [super dealloc];
}


@end
