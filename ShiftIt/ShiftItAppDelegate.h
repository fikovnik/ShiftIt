/*
 ShiftIt: Resize windows with Hotkeys
 Copyright (C) 2010  Aravind
 
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

#import <Cocoa/Cocoa.h>

@class WindowSizer;
@class PreferencesWindowController;
@class FMTHotKeyManager;

@interface ShiftItAppDelegate : NSObject {
 @private
    PreferencesWindowController *preferencesController_;
	FMTHotKeyManager *hotKeyManager_;	
	WindowSizer *windowSizer_;

	NSMutableDictionary *allHotKeys_;
	BOOL paused_;

	NSMenu *statusMenu_;
	NSStatusItem *statusItem_;
	NSImage *statusMenuItemIcon_;
}

- (IBAction)showPreferences:(id)sender;

@end