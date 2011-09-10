//
//  WindowContext.h
//  ShiftIt
//
//  Created by Filip Krikava on 9/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ShiftIt.h"

// TODO: following shoul actually go to something like ShiftIt.h
#define COCOA_TO_SCREEN_COORDINATES(rect) (rect).origin.y = [[NSScreen primaryScreen] frame].size.height - (rect).size.height - (rect).origin.y

@interface SIScreen : NSObject {
@private
	NSRect visibleRect_;
	NSRect screenRect_;
	BOOL primary_;
}

@property (readonly) NSSize size;
@property (readonly) NSRect visibleRect;
@property (readonly) NSRect screenRect;
@property (readonly) BOOL primary;

+ (SIScreen *) screenFromNSScreen:(NSScreen *)screen;
+ (SIScreen *) screenForWindowGeometry:(NSRect)geometry;

- (id) initWithNSScreen:(NSScreen *)screen;

@end

@protocol SIWindow <NSObject>

@required
- (BOOL) getGeometry:(NSRect *)geometry error:(NSError **)error;
- (BOOL) getScreen:(SIScreen **)screen error:(NSError **)error;
- (BOOL) setGeometry:(NSRect)geometry error:(NSError **)error;
- (BOOL) canMove:(BOOL *)flag error:(NSError **)error;
- (BOOL) canResize:(BOOL *)flag error:(NSError **)error;
- (BOOL) canZoom:(BOOL *)flag error:(NSError **)error;
- (BOOL) canEnterFullScreen:(BOOL *)flag error:(NSError **)error;

@optional
- (BOOL) getWindowRect:(NSRect *)windowRect drawersRect:(NSRect *)drawersRect error:(NSError **)error;
- (BOOL) getFullScreen:(BOOL *)flag error:(NSError **)error;
- (BOOL) toggleFullScreen:(NSError **)error;
- (BOOL) toggleZoom:(NSError **)error;

@end

@protocol WindowContext <NSObject>

@required

- (BOOL) getFocusedWindow:(id<SIWindow> *)window error:(NSError **)error;

@end
