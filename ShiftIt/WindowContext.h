//
//  WindowContext.h
//  ShiftIt
//
//  Created by Filip Krikava on 9/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ShiftIt.h"

typedef void* SIWindowRef;

@interface SIScreen : NSObject {
@private
	NSRect visibleRect_;
	NSRect screenRect_;
	BOOL primary_;
}

@property (readonly) NSSize size;
@property (readonly) BOOL primary;

+ (SIScreen *) screenFromNSScreen:(NSScreen *)screen;

- (id) initWithNSScreen:(NSScreen *)screen;

@end

@interface SIWindow : NSObject {
@private	
    SIWindowRef ref_;
    NSRect windowRect_;
    NSRect drawersRect_;
    NSRect geometry_;
    SIScreen *screen_;
}

@property (readonly) NSRect geometry;
@property (readonly) NSPoint origin;
@property (readonly) NSSize size;
@property (readonly) SIScreen *screen;

@end

@protocol WindowContext <NSObject>

- (BOOL) getFocusedWindow:(SIWindow **)window error:(NSError **)error;

- (BOOL) setWindow:(SIWindow *)window geometry:(NSRect)geometry error:(NSError **)error;

@end
