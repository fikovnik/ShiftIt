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

#include "X11Utils.h"

#include <X11/Xlib.h>
#include <X11/Xatom.h>

#include <stdio.h>
#include <assert.h>

static char *kErrorMessages_[] = {
	"X11Error: Unable to to connect to X11 display",
	"X11Error: Unable to get active window (XGetWindowProperty)",
	"X11Error: No X11 active window found"
	"X11Error: Unable to get window attributes (XGetWindowAttributes)",
	"X11Error: Unable to translate coordinated (XTranslateCoordinates)",
	"X11Error: Unable to get geometry (XGetGeometry)"
	"X11Error: Unable to get move/resize window (XMoveResizeWindow)",
	"X11Error: Unable to sync X11 (XSync)",
};

static int kErrorMessageCount_ = 8;

int X11SetWindowGeometry(void *window, int x, int y, unsigned int width, unsigned int height) {
	assert (window != NULL);
	
	Display* dpy = NULL;
	
	// TODO: how expensive is to always get display?
	dpy = XOpenDisplay(NULL);
	
	if (!dpy) {
		return -1;
	}

	if (!XMoveResizeWindow(dpy, *((Window *)window), x, y, width, height)) {
		return -6;
	}
	
	if (!XSync(dpy, False)) {
		return -7;
	}
	
	return 0;
}

void X11FreeWindowRef(void *window) {
	assert (window != NULL);
	
	XFree(window);
}

char *X11GetErrorMessage(int code) {
	assert (code < 0 && code >= -kErrorMessageCount_);
	
	return kErrorMessages_[-code-1];
}

int X11GetActiveWindowGeometry(void **activeWindow, int *x, int *y, unsigned int *width, unsigned int *height) {
	assert (x != NULL && y != NULL && width != NULL && height != NULL);
	
	Display* dpy = NULL;
	dpy = XOpenDisplay(NULL);
	
	if (!dpy) {
		return -1;
	}
	
	Window root = DefaultRootWindow(dpy);
	
	// following are for the params that are not used
	int not_used_int;
	unsigned long not_used_long;
	Window not_used_window;

	Atom actual_type = 0;
	unsigned char *prop_return = NULL;

	if(XGetWindowProperty(dpy, root, XInternAtom(dpy, "_NET_ACTIVE_WINDOW", False), 0, 0x7fffffff, False,
						  XA_WINDOW, &actual_type, &not_used_int, &not_used_long, &not_used_long,
						  &prop_return) != Success) {
		return -2;
	}
	
	Window window = *(unsigned long *) prop_return;

	if (window == 0) {
		return -3;
	}

	XWindowAttributes wa;
    if(!XGetWindowAttributes(dpy, window, &wa)) {
		return -4;
	}
		
	if(!XTranslateCoordinates(dpy, window, wa.root, -wa.border_width, -wa.border_width, x, y, &not_used_window)) {
		return -5;
	}
	
	*x -= wa.x;
	*y -= wa.y;
	*width = wa.width;
	*height = wa.height;
	
	XCloseDisplay(dpy);
	
	*activeWindow = (void *) prop_return;
	return 0;
}
