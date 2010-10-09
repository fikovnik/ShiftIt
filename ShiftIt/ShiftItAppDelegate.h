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
#import "PrefWindowController.h"

@interface ShiftItAppDelegate : NSObject {
 @private
    PrefWindowController * prefController_;
    Preferences * pref_;
	NSMenu *statusMenu_;
	NSStatusItem *statusItem_;
	
	NSImage *statusMenuItemIcon_;
}

@property (nonatomic, retain) IBOutlet NSMenu *statusMenu;

-(void)updateMenuBarIcon;
-(void)registerForLogin;
-(void)updateStatusMenuShortcuts;

-(IBAction)showPreferences:(id)sender;

@end