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

// FCE prototypes
extern short GetMBarHeight(void);

extern NSString *const SIErrorDomain;
extern NSInteger const kShiftItManagerFailureErrorCode;
// TODO: change this to be the AX error specific
extern NSInteger const kWindowManagerFailureErrorCode;
extern NSInteger const kShiftItActionFailureErrorCode;

extern NSString *const kMarginsEnabledPrefKey;
extern NSString *const kLeftMarginPrefKey;
extern NSString *const kTopMarginPrefKey;
extern NSString *const kBottomMarginPrefKey;
extern NSString *const kRightMarginPrefKey;

#define POINT_STR(point) FMTStr(@"[%.1f %.1f]", (point).x, (point).y)
#define SIZE_STR(size) FMTStr(@"[%.1f x %.1f]", (size).width, (size).height)
#define RECT_STR(rect) FMTStr(@"[%.1f %.1f] [%.1f %.1f] [%.1f x %.1f]", (rect).origin.x, (rect).origin.y, (rect).origin.x+(rect).size.width, (rect).origin.y+(rect).size.height, (rect).size.width, (rect).size.height)
#define COCOA_TO_SCREEN_COORDINATES(rect) (rect).origin.y = [[NSScreen primaryScreen] frame].size.height - (rect).size.height - (rect).origin.y

#define SICreateError(errorCode, fmt, ...) FMTCreateError(SIErrorDomain, errorCode, fmt, ##__VA_ARGS__)
#define SICreateErrorWithCause(errorCode, cause, fmt, ...) FMTCreateErrorWithCause(SIErrorDomain, errorCode, cause, fmt, ##__VA_ARGS__)

#define TO_SCREEN_ORIGIN(geometry, screen) \
    (geometry).origin.x -= [(screen) visibleRect].origin.x; \
    (geometry).origin.y -= [(screen) visibleRect].origin.y;
//    (geometry).origin.x = -([(screen) rect].origin.x - (geometry).origin.x); \
//    (geometry).origin.y = -([(screen) rect].origin.y - (geometry).origin.y);

#define TO_CG_ORIGIN(geometry, screen) \
    (geometry).origin.x += [(screen) visibleRect].origin.x; \
    (geometry).origin.y += [(screen) visibleRect].origin.y;

@interface NSScreen (Extras)

+ (NSScreen *)primaryScreen;
- (BOOL)isPrimary;
- (BOOL)isBelowPrimary;
- (NSRect)screenFrame;
- (NSRect)screenVisibleFrame;

@end

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

/**
* @param geometry a pointer to a NSRect where the current geometry of a window will be stored. It can be nil in which case no information will be stored.
* @param screen a pointer to a SIScreen where the current screen of a window will be stored. It can be nil in which case no information will be stored.
* @param shall there be a problem obtaining the window geometry information the cause will be stored in this pointer if it is not nil.
*
* @returns YES on success, NO otherwise while setting the error parameter
*/
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
- (BOOL) anchorWindow:(id<SIWindow>)window error:(NSError **)error;
- (BOOL)getAnchorMargins:(int *)leftMargin topMargin:(int *)topMargin bottomMargin:(int *)bottomMargin rightMargin:(int *)rightMargin;
@end

@protocol ShiftItActionDelegate <NSObject>

@required
- (BOOL) execute:(id<WindowContext>)windowContext error:(NSError **)error;

@end

typedef enum {
    kLeftDirection = 1 << 0,
    kTopDirection = 1 << 1,
    kBottomDirection = 1 << 2,
    kRightDirection = 1 << 3
} Direction;

// TODO: move to FMT
static inline double SIDistanceBetweenPoints(NSPoint r, NSPoint s) {
    return sqrt((r.x-s.x)*(r.x-s.x) +(r.y-s.y)*(r.y-s.y));
}

// TODO: move to FMT
static inline double SIArea(NSSize s) {
    return s.width * s.height;
}

extern void GetAnchorMargin(int *leftMargin, int *topMargin, int *bottomMargin, int *rightMargin);