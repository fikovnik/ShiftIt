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

// This file is based on CGSPrivate.h by Richard Wareham

#import <Carbon/Carbon.h>

typedef int		CGSConnection;
typedef int		CGSWindow;
typedef int		CGSWorkspace;

#pragma mark Core Functions

/* Get the default connection for the current process. */
extern CGSConnection _CGSDefaultConnection(void);

#pragma mark Workspace Functions

extern Boolean CoreDockGetWorkspacesEnabled();	
extern void CoreDockGetWorkspacesCount(int *rows, int *cols);

extern CGError CGSMoveWorkspaceWindowList(const CGSConnection connection, CGSWindow *wids, int count, CGSWorkspace toWorkspace);