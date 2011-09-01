//
//  WindowDriver.h
//  ShiftIt
//
//  Created by Filip Krikava on 9/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WindowContext.h"

@protocol WindowDriver <NSObject>

- (BOOL) getFocusedWindow:(SIWindowRef *)windowRef error:(NSError **)error;

- (void) freeWindow:(SIWindowRef)windowRef;

- (BOOL) setWindow:(SIWindowRef)windowRef position:(NSPoint)position error:(NSError **)error;

- (BOOL) setWindow:(SIWindowRef)windowRef size:(NSSize)size error:(NSError **)error;

- (BOOL) getWindow:(SIWindowRef)windowRef geometry:(NSRect *)geometry error:(NSError **)error;

- (BOOL) getWindow:(SIWindowRef)windowRef drawersGeometry:(NSRect *)geometry error:(NSError **)error;

- (BOOL) isWindow:(SIWindowRef)windowRef inFullScreen:(BOOL *)fullScreen error:(NSError **)error;

- (BOOL) canWindow:(SIWindowRef)window resize:(BOOL *)resizeable error:(NSError **)error;

- (BOOL) canWindow:(SIWindowRef)window move:(BOOL *)moveable error:(NSError **)error;

- (BOOL) toggleZoomOnWindow:(SIWindowRef)window error:(NSError **)error;

- (BOOL) toggleFullScreenOnWindow:(SIWindowRef)window error:(NSError **)error;

@end
