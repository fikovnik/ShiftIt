/*
 ShiftIt: Resize windows with Hotkeys
 Copyright (C) 2010  Filip Krikava
 
 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/>.
 
 */

#include <assert.h>
#include <stdio.h>
#include <dlfcn.h>
#include <X11/Xlib.h>
#include <X11/Xatom.h>

#include "X11Utils.h"

Display *(*XOpenDisplayRef)(char *display_name);
int (*XCloseDisplayRef)(Display *display);
int (*XFreeRef)(void *data);
int (*XSetErrorHandlerRef)(int (*handler)(Display *, XErrorEvent *));
int (*XGetErrorTextRef)(Display *display, int code, char *buffer_return, int length);
int (*XSyncRef)(Display *display, Bool discard);
int (*XMoveWindowRef)(Display *display, Window w, int x, int y);
int (*XResizeWindowRef)(Display *display, Window w, unsigned width, unsigned height);
Status (*XGetWindowAttributesRef)(Display *display, Window w, XWindowAttributes *window_attributes_return);
int (*XGetWindowPropertyRef)(Display *display, Window w, Atom property, long long_offset, long long_length, Bool delete, Atom
					   req_type, Atom *actual_type_return, int *actual_format_return, unsigned long *nitems_return, unsigned long
					   *bytes_after_return, unsigned char **prop_return);
Atom (*XInternAtomRef)(Display *display, char *atom_name, Bool only_if_exists);
Bool (*XTranslateCoordinatesRef)(Display *display, Window src_w, Window dest_w, int src_x, int src_y, int *dest_x_return, int
								   *dest_y_return, Window *child_return);

void *X11Symbols_[][2] = {
	{&XCloseDisplayRef,"XCloseDisplay"},
	{&XFreeRef,"XFree"},
	{&XGetErrorTextRef,"XGetErrorText"},
	{&XGetWindowAttributesRef,"XGetWindowAttributes"},
	{&XGetWindowPropertyRef,"XGetWindowProperty"},
	{&XInternAtomRef,"XInternAtom"},
	{&XMoveWindowRef,"XMoveWindow"},
	{&XOpenDisplayRef,"XOpenDisplay"},
	{&XResizeWindowRef,"XResizeWindow"},
	{&XSetErrorHandlerRef,"XSetErrorHandler"},
	{&XSyncRef,"XSync"},
	{&XTranslateCoordinatesRef,"XTranslateCoordinates"},
};

char *X11Paths_[] = {
	"libX11.6.dylib",
	"/usr/X11/lib/libX11.6.dylib", // regular
	"/opt/local/X11/lib/libX11.6.dylib", // MacPorts?
	"/sw/X11/lib/libX11.6.dylib", // Fink?
};

static int X11Initialized_ = 0;
static int X11Available_ = 0;
static void *X11Lib_ = NULL;

int InitializeX11Support() {
	if (X11Initialized_ == 1) {
		return X11Available_;
	}

	X11Initialized_ = 1;
	
	// try to load the library
	int found=0;
	for (int i=0; i<sizeof(X11Paths_)/sizeof(X11Paths_[0]); i++) {
		X11Lib_ = dlopen(X11Paths_[i], RTLD_LOCAL | RTLD_NOW);
		if (!X11Lib_) {
			printf("X11Info: Unable to load X11 library from: %s: %s\n", X11Paths_[i], dlerror());
		} else {
			found = 1;
			break;
		}
	}
	
	if (!found) {
		printf("X11Info: No libX11 found - X11 support will be disabled\n");
		X11Available_ = 0;
		return 0;
	}
	
	// try to load symbols
	char *err;
	for (int i=0; i<sizeof(X11Symbols_)/sizeof(X11Symbols_[0]); i++) {
		*(void **)(X11Symbols_[i][0]) = dlsym(X11Lib_, X11Symbols_[i][1]);
		if ((err = dlerror()) != NULL) {
			fprintf(stderr,"X11Error: Unable to load X11 symbol: %s: %s\n", (char *)(X11Symbols_[i][1]), err);
			dlclose(X11Lib_);
			X11Lib_ = NULL;
			return 0;
		}
	}
	
	X11Available_ = 1;
	return 1;
}

void DestoryX11Support() {
	if (X11Lib_) {
		dlclose(X11Lib_);
	}
}

static const char *const kErrorMessages_[] = {
	"X11Error: Unable to to connect to X11 display",
	"X11Error: Unable to get active window (XGetWindowProperty)",
	"X11Error: No X11 active window found",
	"X11Error: Unable to get window attributes (XGetWindowAttributes)",
	"X11Error: Unable to translate coordinated (XTranslateCoordinates)",
	"X11Error: Unable to get geometry (XGetGeometry)",
	"X11Error: Unable to change window geometry (XMoveResizeWindow)",
	"X11Error: Unable to sync X11 (XSync)"
};

static int kErrorMessageCount_ = sizeof(kErrorMessages_)/sizeof(kErrorMessages_[0]);

static int ShiftItX11ErrorHandler(Display *dpy, XErrorEvent *err) {
	char msg[256];
	
	XGetErrorTextRef(dpy, err->error_code, msg, sizeof(msg));
	printf("ShiftIt: X11Error: %s (code: %d)\n", msg, err->request_code);
		
	return 0;
}

int X11SetWindowPosition(void *window, int x, int y) {
	assert (window != NULL);
	
	Display *dpy = XOpenDisplayRef(NULL);
	
	if (!dpy) {
		return -1;
	}
	
	XSetErrorHandlerRef(&ShiftItX11ErrorHandler);
	
	// we don't need to adjust the x and y since they are from the top left window	
	if (!XMoveWindowRef(dpy, *((Window *)window), x, y)){
		return -6;
	}
	
	// do it now - this will block
	if (!XSyncRef(dpy, False)) {
		return -7;
	}
	
	XCloseDisplayRef(dpy);
	return 0;	
}

int X11SetWindowSize(void *window, unsigned int width, unsigned int height) {
	assert (window != NULL);
	
	Display *dpy = XOpenDisplayRef(NULL);
	
	if (!dpy) {
		return -1;
	}
	
	XSetErrorHandlerRef(&ShiftItX11ErrorHandler);
	
	XWindowAttributes wa;
    if(!XGetWindowAttributesRef(dpy, *((Window *)window), &wa)) {
		return -4;
	}
	
	// the WindowSizer will pass the size of the entire window including its decoration
	// we need to subtract that
	width -= wa.x;
	height -= wa.y;
		
	if (!XResizeWindowRef(dpy, *((Window *)window), width, height)){
		return -6;
	}
	
	if (!XSyncRef(dpy, False)) {
		return -7;
	}
	
	XCloseDisplayRef(dpy);
	return 0;
}

int X11GetActiveWindow(void **activeWindow) {
	Display* dpy = NULL;
	dpy = XOpenDisplayRef(NULL);
	
	if (!dpy) {
		return -1;
	}
	
	XSetErrorHandlerRef(&ShiftItX11ErrorHandler);
	
	Window root = DefaultRootWindow(dpy);
	
	// following are for the params that are not used
	int not_used_int;
	unsigned long not_used_long;
	
	Atom actual_type = 0;
	unsigned char *prop_return = NULL;
	
	if(XGetWindowPropertyRef(dpy, root, XInternAtomRef(dpy, "_NET_ACTIVE_WINDOW", False), 0, 0x7fffffff, False,
						  XA_WINDOW, &actual_type, &not_used_int, &not_used_long, &not_used_long,
						  &prop_return) != Success) {
		return -2;
	}
	
	if (prop_return == NULL || *((Window *) prop_return) == 0) {
		return -3;
	}
	
	*activeWindow = (void *) prop_return;	
	
	XCloseDisplayRef(dpy);
	return 0;
}

int X11GetWindowGeometry(void *window, int *x, int *y, unsigned int *width, unsigned int *height) {
	assert (x != NULL && y != NULL && width != NULL && height != NULL);

	Display* dpy = NULL;
	dpy = XOpenDisplayRef(NULL);
	
	if (!dpy) {
		return -1;
	}
	
	XSetErrorHandlerRef(&ShiftItX11ErrorHandler);

	Window root = DefaultRootWindow(dpy);
	XWindowAttributes wa;
	
    if(!XGetWindowAttributesRef(dpy, *((Window *)window), &wa)) {
		return -4;
	}
	
	Window not_used_window;
	if(!XTranslateCoordinatesRef(dpy, *((Window *)window), root, -wa.border_width, -wa.border_width, x, y, &not_used_window)) {
		return -5;
	}
	
	// the height returned is without the window manager decoration - the OSX top bar with buttons, window label and stuff
	// so we need to add it to the height as well because the WindowSize expects the full window
	// the same might be potentially apply to the width
	*width = wa.width + wa.x;
	*height = wa.height + wa.y;
	
	*x -= wa.x;
	*y -= wa.y;
	
	XCloseDisplayRef(dpy);	
	return 0;	
}

void X11FreeWindowRef(void *window) {
	assert(window != NULL);
	
	XFreeRef(window);
}

const char *X11GetErrorMessage(int code) {
	assert (code < 0 && code >= -kErrorMessageCount_);

	return kErrorMessages_[-code-1];
}
