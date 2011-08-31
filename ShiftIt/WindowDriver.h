//
//  WindowDriver.h
//  ShiftIt
//
//  Created by Filip Krikava on 9/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void* SIWindowRef;

@protocol WindowDriver <NSObject>

- (BOOL) getFocusedWindow:(SIWindowRef *)windowRef error:(NSError **)error;

- (void) freeWindow:(SIWindowRef)windowRef;

- (BOOL) setPosition:(NSPoint)position window:(SIWindowRef)windowRef error:(NSError **)error;

- (BOOL) setSize:(NSSize)size window:(SIWindowRef)windowRef error:(NSError **)error;

- (BOOL) getGeometry:(NSRect *)rect window:(SIWindowRef)windowRef error:(NSError **)error;

- (BOOL) getDrawersGeometry:(NSRect *)rect window:(SIWindowRef)windowRef error:(NSError **)error;

- (BOOL) getFullScreenMode:(BOOL *)fullScreen window:(SIWindowRef)windowRef error:(NSError **)error;

- (BOOL) getPosition:(NSPoint *)position element:(SIWindowRef)element error:(NSError **)error;

- (BOOL) getSize:(NSSize *)size element:(SIWindowRef)element error:(NSError **)error;

- (BOOL) isWindowResizeable:(SIWindowRef)window;

- (BOOL) isWindowMoveable:(SIWindowRef)window;

@end
