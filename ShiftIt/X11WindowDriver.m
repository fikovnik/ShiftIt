//
//  X11WindowDriver.m
//  ShiftIt
//
//  Created by Filip Krikava on 9/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <dlfcn.h>

#import "X11WindowDriver.h"
#import "FMTDefines.h"
#import "ShiftIt.h"

#pragma mark Constants

NSInteger const kX11WindowDriverErrorCode = 20105;

#pragma mark Xlib Function Pointers

// following functions pointers will be associated once, at the first 
// initialization

// TODO: extract
static char *X11Paths_[] = {
	"libX11.6.dylib",
    "/usr/local/X11/libX11.6.dylib", // anyone?
	"/usr/X11/lib/libX11.6.dylib", // regular
	"/opt/local/X11/lib/libX11.6.dylib", // MacPorts?
	"/sw/X11/lib/libX11.6.dylib", // Fink?
};

// X11 function pointers
static Display *(*XOpenDisplayRef)(char *display_name);
static int (*XCloseDisplayRef)(Display *display);
static int (*XFreeRef)(void *data);
static int (*XSetErrorHandlerRef)(int (*handler)(Display *, XErrorEvent *));
static int (*XGetErrorTextRef)(Display *display, int code, char *buffer_return, int length);
static int (*XSyncRef)(Display *display, Bool discard);
static int (*XMoveWindowRef)(Display *display, Window w, int x, int y);
static int (*XResizeWindowRef)(Display *display, Window w, unsigned width, unsigned height);
static Status (*XGetWindowAttributesRef)(Display *display, Window w, XWindowAttributes *window_attributes_return);
static int (*XGetWindowPropertyRef)(Display *display, Window w, Atom property, long long_offset, long long_length, Bool delete, Atom
                             req_type, Atom *actual_type_return, int *actual_format_return, unsigned long *nitems_return, unsigned long
                             *bytes_after_return, unsigned char **prop_return);
static Atom (*XInternAtomRef)(Display *display, char *atom_name, Bool only_if_exists);
static Bool (*XTranslateCoordinatesRef)(Display *display, Window src_w, Window dest_w, int src_x, int src_y, int *dest_x_return, int
                                 *dest_y_return, Window *child_return);
static Status (*XQueryTreeRef)(Display *display, Window w, Window *root_return, Window *parent_return, Window
                        **children_return, unsigned int *nchildren_return);

// X11 symbols table

#define X11_SYMBOL(s) {&s##Ref,#s}
static void *X11Symbols_[][2] = {
    X11_SYMBOL(XCloseDisplay),
    X11_SYMBOL(XFree),
    X11_SYMBOL(XGetErrorText),
    X11_SYMBOL(XGetWindowAttributes),
    X11_SYMBOL(XGetWindowProperty),
    X11_SYMBOL(XInternAtom),
    X11_SYMBOL(XMoveWindow),
    X11_SYMBOL(XOpenDisplay),
    X11_SYMBOL(XResizeWindow),
    X11_SYMBOL(XSetErrorHandler),
    X11_SYMBOL(XSync),
    X11_SYMBOL(XTranslateCoordinates),
    X11_SYMBOL(XQueryTree)
};
#undef X11_SYMBOL

// not null if the X11 functions have been loaded
static void *X11Lib_ = NULL;

static int ShiftItX11ErrorHandler(Display *dpy, XErrorEvent *err) {
	char msg[1024];

	XGetErrorTextRef(dpy, err->error_code, msg, sizeof(msg));
	FMTLogError(@"X11Error: %s (code: %d)\n", msg, err->request_code);

	return 0;
}

#pragma mark X11 display execution support

typedef BOOL(^ExecWithDisplayBlock)(Display *, NSError **);

static BOOL execWithDisplay_(ExecWithDisplayBlock block, NSError ** error) {
    Display *dpy = XOpenDisplayRef(NULL);
    if (!dpy) {
		return NO;
	}

	XSetErrorHandlerRef(&ShiftItX11ErrorHandler);
    // TODO: set IOErrorHandler

    BOOL ret = block(dpy, error);

    XCloseDisplayRef(dpy);

    return ret;
}

#pragma mark X11Window

@interface X11Window : NSObject<SIWindow> {
@private
    Window *ref_;
    X11WindowDriver *driver_;
}

@property (readonly) Window *ref_;
@property (readonly) X11WindowDriver *driver_;

- (id) initWithRef:(Window *)ref
            driver:(X11WindowDriver *)driver;

@end

@interface X11WindowDriver()

- (BOOL) loadX11_:(NSError **)error;

@end

#pragma mark Window Delegate Functions

@interface X11WindowDriver(WindowDelegate)

- (BOOL) getGeometry_:(NSRect *)geometry screen:(SIScreen **)screen ofWindow:(Window *)windowRef error:(NSError **)error;
- (BOOL) setGeometry_:(NSRect)geometry screen:(SIScreen *)screen ofWindow:(Window *)windowRef error:(NSError **)error;
- (void) freeWindow_:(Window *)windowRef;
//- (BOOL) canResize_:(BOOL *)flag window:(AXUIElementRef)windowRef error:(NSError **)error;
//- (BOOL) canMove_:(BOOL *)flag window:(AXUIElementRef)windowRef error:(NSError **)error;

@end

#pragma mark X11Window Implementation

@implementation X11Window

@synthesize ref_;
@synthesize driver_;

- (id) initWithRef:(Window *)ref
            driver:(X11WindowDriver *)driver {

	FMTAssertNotNil(driver);

	if (![super init]) {
		return nil;
	}

	ref_ = ref;
    driver_ = [driver retain];

	return self;
}

- (void) dealloc {
    [driver_ freeWindow_:ref_];

    [driver_ release];

	[super dealloc];
}

- (BOOL)getGeometry:(NSRect *)geometry screen:(SIScreen **)screen error:(NSError **)error {
    return [driver_ getGeometry_:geometry screen:screen ofWindow:ref_ error:error];
}

- (BOOL)setGeometry:(NSRect)geometry screen:(SIScreen *)screen error:(NSError **)error {
    return [driver_ setGeometry_:geometry screen:screen ofWindow:ref_ error:error];
}

- (BOOL) canZoom:(BOOL *)flag error:(NSError **)error {
    *flag = NO;
    return YES;
}

- (BOOL) canEnterFullScreen:(BOOL *)flag error:(NSError **)error {
    *flag = NO;
    return YES;
}

- (BOOL) canMove:(BOOL *)flag error:(NSError **)error {
    // TODO: do the actual check
    *flag = YES;
    return YES;
}

- (BOOL) canResize:(BOOL *)flag error:(NSError **)error {
    // TODO: do the actual check
    *flag = YES;
    return YES;
}

@end


@implementation X11WindowDriver

- (id)initWithError:(NSError **)error {
    if(![super init]) {
        return nil;
    }

    if (![self loadX11_:error]) {
        [self release];
        return nil;
    }

    return self;
}

- (BOOL)loadX11_:(NSError **)error {
    if (X11Lib_) {
        return YES;
    }

	// try to load the library
	int found=0;
	for (int i=0; i<sizeof(X11Paths_)/sizeof(X11Paths_[0]); i++) {
		X11Lib_ = dlopen(X11Paths_[i], RTLD_LOCAL | RTLD_NOW);
		if (!X11Lib_) {
			FMTLogDebug(@"X11Info: Unable to load X11 library from: %s: %s\n", X11Paths_[i], dlerror());
		} else {
			found = 1;
            FMTLogDebug(@"X11Info: loaded X11 library from: %s\n", X11Paths_[i]);
			break;
		}
	}

	if (!found) {
        if (error) {
		    *error = SICreateError(kX11WindowDriverErrorCode,
                                   @"X11Info: No libX11 found - X11 support will be disabled\n");
        }
        return NO;
	}

	// try to load the X11 symbols
	char *err = NULL;
	for (int i=0; i<sizeof(X11Symbols_)/sizeof(X11Symbols_[0]); i++) {
		*(void **)(X11Symbols_[i][0]) = dlsym(X11Lib_, X11Symbols_[i][1]);
		if ((err = dlerror()) != NULL) {
            if (error) {
			    *error = SICreateError(kX11WindowDriverErrorCode,
                                       @"X11Error: Unable to load X11 symbol: %s: %s\n",
                                       (char *)(X11Symbols_[i][1]), err);
            }

			dlclose(X11Lib_);
			X11Lib_ = NULL;

			return NO;
		}
	}

	return YES;
}

- (void) dealloc {
    if (X11Lib_) {
		dlclose(X11Lib_);
	}

    [super dealloc];
}

- (BOOL) findFocusedWindow:(id<SIWindow> *)window withInfo:(SIWindowInfo *)windowInfo error:(NSError **)error {
	FMTAssertNotNil(error);

    Window __block * windowRef;

    // find the focused window
    execWithDisplay_(^BOOL(Display *dpy, NSError **error) {
        Window root = DefaultRootWindow(dpy);

        // following are for the params that are not used
        int not_used_int;
        unsigned long not_used_long;

        Atom actual_type = 0;
        unsigned char *prop_return = NULL;

        if(XGetWindowPropertyRef(dpy, root, XInternAtomRef(dpy, "_NET_ACTIVE_WINDOW", False), 0, 0x7fffffff, False,
                                 XA_WINDOW, &actual_type, &not_used_int, &not_used_long, &not_used_long,
                                 &prop_return) != Success) {
            *error = SICreateError(kX11WindowDriverErrorCode, @"Unable to get active window (XGetWindowProperty)");
            return NO;
        }

        if (prop_return == NULL || *((Window *) prop_return) == 0) {
            *error = SICreateError(kX11WindowDriverErrorCode, @"No X11 active window found");
            return NO;
        }

        windowRef = (Window *) prop_return;
        return YES;
    }, error);

    // verify that this is the window that we were asked to find


    *window = [[[X11Window alloc] initWithRef:windowRef driver:self] autorelease];

    return YES;
}

@end

@implementation X11WindowDriver (WindowDelegate)

- (BOOL)getGeometry_:(__block NSRect *)geometry screen:(__block SIScreen **)screen ofWindow:(Window *)windowRef error:(NSError **)error {
    return execWithDisplay_(^BOOL(Display *dpy, NSError **error) {
        Window root = DefaultRootWindow(dpy);
        XWindowAttributes wa;

        if(!XGetWindowAttributesRef(dpy, *windowRef, &wa)) {
            *error = SICreateError(kX11WindowDriverErrorCode, @"Unable to get window attributes (XGetWindowAttributes)");
            return NO;
        }

        int x, y;
        unsigned int width, height;
        Window not_used_window;
        if(!XTranslateCoordinatesRef(dpy, *windowRef, root, -wa.border_width, -wa.border_width, &x, &y, &not_used_window)) {
            *error = SICreateError(kX11WindowDriverErrorCode, @"Unable to translate coordinated (XTranslateCoordinates)");
            return NO;
        }

        // the height returned is without the window manager decoration - the OSX top bar with buttons, window label and stuff
        // so we need to add it to the height as well because the WindowSize expects the full window
        // the same might be potentially apply to the width
        width = (unsigned int) (wa.width + wa.x);
        height = (unsigned int) (wa.height + wa.y);

        x -= wa.x;
        y -= wa.y;

        if (geometry) {
            *geometry = NSMakeRect(x, y, width, height);
        }
        if (screen) {
            *screen = [SIScreen screenForWindowGeometry:*geometry];
        }

        return YES;
	}, error);
}

- (BOOL)setGeometry_:(NSRect)geometry screen:(SIScreen **)screen ofWindow:(Window *)windowRef error:(NSError **)error {
    FMTAssertNotNil(screen);

    return execWithDisplay_(^BOOL(Display *dpy, NSError **error) {
        // TODO: combine the operations
        // we don't need to adjust the x and y since they are from the top left window
            if (!XMoveWindowRef(dpy, *windowRef, geometry.origin.x, geometry.origin.y)){
                if (error) {
                    *error = SICreateError(kX11WindowDriverErrorCode, @"Unable to get move window (XMoveWindow)");
                }
                return NO;
            }

            // do it now - this will block
            if (!XSyncRef(dpy, False)) {
                if (error) {
                    *error = SICreateError(kX11WindowDriverErrorCode, @"X11Error: Unable to sync X11 (XSync)");
                }
                return NO;
            }
        
        XWindowAttributes wa;
        if(!XGetWindowAttributesRef(dpy, *windowRef, &wa)) {
            if (error) {
                *error = SICreateError(kX11WindowDriverErrorCode, @"Unable to get window attributes (XGetWindowAttributes)");
            }
            return NO;
        }

        // the WindowSizer will pass the size of the entire window including its decoration
        // we need to subtract that
        unsigned int width = (unsigned int) (geometry.size.width - wa.x);
        unsigned int height = (unsigned int) (geometry.size.height - wa.y);

        if (!XResizeWindowRef(dpy, *windowRef, width, height)){
            if (error) {
                *error = SICreateError(kX11WindowDriverErrorCode, @"X11Error: Unable to change window geometry (XMoveResizeWindow)");
            }
            return NO;
        }

        if (!XSyncRef(dpy, False)) {
            if (error) {
                *error = SICreateError(kX11WindowDriverErrorCode, @"X11Error: Unable to sync X11 (XSync)");
            }
            return NO;
        }

        return YES;
	}, error);
}


- (void) freeWindow_:(Window *)windowRef {
    XFreeRef(windowRef);
}


@end