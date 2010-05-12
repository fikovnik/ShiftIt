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

#include "Preferences.h"

@interface PrefWindowController : NSWindowController {
    IBOutlet NSTextField * _top;
    IBOutlet NSTextField * _bottom;
    IBOutlet NSTextField * _left;
    IBOutlet NSTextField * _right;
    
    IBOutlet NSTextField * _topLeft;
    IBOutlet NSTextField * _topRight;
    IBOutlet NSTextField * _bottomLeft;
    IBOutlet NSTextField * _bottomRight;
    
    IBOutlet NSTextField * _fullScreen;
    IBOutlet NSTextField * _center;
    
    IBOutlet NSButton * _openAtLogin;
    IBOutlet NSTabView * tabView;
}

-(IBAction)savePreferences:(id)sender;
-(IBAction)closePreferences:(id)sender;
-(IBAction)showPreferences:(id)sender;
@end
