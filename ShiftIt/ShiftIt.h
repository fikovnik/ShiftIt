//
//  ShiftIt.h
//  ShiftIt
//
//  Created by Filip Krikava on 9/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "FMTDefines.h"
#import "FMTUtils.h"
#import "FMTNSArray+Extras.h"
#import "FMTNSError+Extras.h"

extern NSString *const SIErrorDomain;
extern NSInteger const kWindowManagerFailureErrorCode;

#define POINT_STR(point) FMTStr(@"[%f %f]", (point).x, (point).y)
#define SIZE_STR(size) FMTStr(@"[%f %f]", (size).width, (size).height)
#define RECT_STR(rect) FMTStr(@"[%f %f] [%f %f] [%f %f]", (rect).origin.x, (rect).origin.y, (rect).origin.x+(rect).size.width, (rect).origin.y+(rect).size.height, (rect).size.width, (rect).size.height)
#define COCOA_TO_SCREEN_COORDINATES(rect) (rect).origin.y = [[NSScreen primaryScreen] frame].size.height - (rect).size.height - (rect).origin.y

#define SICreateError(errorCode, fmt, ...) FMTCreateError(SIErrorDomain, errorCode, fmt, ##__VA_ARGS__)
#define SICreateErrorWithCause(errorCode, cause, fmt, ...) FMTCreateErrorWithCause(SIErrorDomain, errorCode, cause, fmt, ##__VA_ARGS__)

@interface SIWindowInfo : NSObject {
@private
    pid_t pid_;
    CGWindowID wid_;
    NSRect rect_;
}

@property (readonly) pid_t pid;
@property (readonly) CGWindowID wid;
@property (readonly) NSRect rect;

+ (SIWindowInfo *) windowInfoFromCGWindowInfoDictionary:(NSDictionary *)windowInfo;

@end

@interface SIScreen : NSObject {
@private
    NSScreen *screen_;
}

@property (readonly) NSSize size;
@property (readonly) NSRect visibleRect;
@property (readonly) NSRect rect;
@property (readonly) BOOL primary;

+ (SIScreen *) screenFromNSScreen:(NSScreen *)screen;
+ (SIScreen *) screenForWindowGeometry:(NSRect)geometry;

- (id) initWithNSScreen:(NSScreen *)screen;

@end

@protocol SIWindow <NSObject>

@required
- (BOOL) getGeometry:(NSRect *)geometry screen:(SIScreen **)screen error:(NSError **)error;
- (BOOL) setGeometry:(NSRect)geometry screen:(SIScreen *)screen error:(NSError **)error;
- (BOOL) canMove:(BOOL *)flag error:(NSError **)error;
- (BOOL) canResize:(BOOL *)flag error:(NSError **)error;
- (BOOL) canZoom:(BOOL *)flag error:(NSError **)error;
- (BOOL) canEnterFullScreen:(BOOL *)flag error:(NSError **)error;

@optional
- (BOOL) getWindowRect:(NSRect *)windowRect screen:(SIScreen **)screen drawersRect:(NSRect *)drawersRect error:(NSError **)error;
- (BOOL) getFullScreen:(BOOL *)flag error:(NSError **)error;
- (BOOL) toggleFullScreen:(NSError **)error;
- (BOOL) toggleZoom:(NSError **)error;

@end

@protocol WindowContext <NSObject>

@required
- (BOOL) getFocusedWindow:(id<SIWindow> *)window error:(NSError **)error;

@end

@protocol ShiftItAction <NSObject>

@required
- (BOOL) execute:(id<WindowContext>)windowContext error:(NSError **)error;

@end

// TODO: move to FMT
static inline double SIDistanceBetweenPoints(NSPoint r, NSPoint s) {
    return sqrt((r.x-s.x)*(r.x-s.x) +(r.y-s.y)*(r.y-s.y));
}

// TODO: move to FMT
static inline double SIArea(NSSize s) {
    return s.width * s.height;
}

// TODO: move to FMT
static inline double SIRectArea(NSRect r) {
    return SIArea(r.size);
}

