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

#ifndef _X11UTIL_H_

#define _X11UTIL_H_

/**
 * This unit defines necessary functions to support sizing of X11 windows
 * It is based upon the Xlib library [1].
 * 
 * [1] http://tronche.com/gui/x/xlib/
 *
 */

int X11SetWindowPosition(void *window, int x, int y);
int X11SetWindowSize(void *window, unsigned int width, unsigned int height);
int X11GetActiveWindow(void **activeWindow);
int X11GetWindowGeometry(void *window, int *x, int *y, unsigned int *width, unsigned int *height);
void X11FreeWindowRef(void *window);

const char *X11GetErrorMessage(int code);

#endif // _X11UTIL_H_
