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

#define TO_CG_ORIGIN(geometry, screen) \
    (geometry).origin.x += [(screen) visibleRect].origin.x; \
    (geometry).origin.y += [(screen) visibleRect].origin.y;

// TODO: move to FMT
static inline double SIDistanceBetweenPoints(NSPoint r, NSPoint s) {
    return sqrt((r.x-s.x)*(r.x-s.x) +(r.y-s.y)*(r.y-s.y));
}

// TODO: move to FMT
static inline double SIArea(NSSize s) {
    return s.width * s.height;
}

extern void GetAnchorMargin(int *leftMargin, int *topMargin, int *bottomMargin, int *rightMargin);