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

int AXUISetWindowPosition(void *window, int x, int y);
int AXUISetWindowSize(void *window, unsigned int width, unsigned int height);
int AXUIGetActiveWindow(void **activeWindow);
int AXUIGetWindowGeometry(void *window, int *x, int *y, unsigned int *width, unsigned int *height);
int AXUIGetWindowDrawersUnionRect(void *window, NSRect *rect);
void AXUIFreeWindowRef(void *window);

const char *AXUIGetErrorMessage(int code);