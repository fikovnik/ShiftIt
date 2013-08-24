//
//  SILeapController.h
//  ShiftIt
//
//  Created by myeyesareblind on 8/24/13.
//
//

#import <Foundation/Foundation.h>

typedef void(^SILeapControllerGestureHandleBlock)(NSString* actionIdentifier);

@interface SILeapController : NSObject

-(id) init;

@property (readwrite, copy) SILeapControllerGestureHandleBlock gestureHandleBlock;

@end
