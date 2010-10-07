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
#import <ShortcutRecorder/ShortcutRecorder.h>

#include "Preferences.h"
#include "SIHotKey.h"
#include "hKController.h"

@interface PrefWindowController : NSWindowController {
    hKController *hkContObject;
    IBOutlet NSButton * _openAtLogin;
    IBOutlet NSTabView * tabView;
	IBOutlet NSTextField * versionLabel;
	
	IBOutlet SRRecorderControl *leftRecorderCtrl;
	IBOutlet SRRecorderControl *rightRecorderCtrl;
	IBOutlet SRRecorderControl *topRecorderCtrl;
	IBOutlet SRRecorderControl *bottomRecorderCtrl;

	IBOutlet SRRecorderControl *tlRecorderCtrl;
	IBOutlet SRRecorderControl *trRecorderCtrl;
	IBOutlet SRRecorderControl *blRecorderCtrl;
	IBOutlet SRRecorderControl *brRecorderCtrl;

	IBOutlet SRRecorderControl *fullScreenRecorderCtrl;
	IBOutlet SRRecorderControl *centerRecorderCtrl;

	NSArray *recorderCtlArray;
	
	NSInteger buttonPressed;
	NSMenu *statusMenu;
}

-(IBAction)showPreferences:(id)sender;
-(void)updateRecorderCombos;

@property (nonatomic, retain) NSArray *recorderCtlArray;
@property (nonatomic) NSInteger buttonPressed;
@property (nonatomic, retain) NSMenu *statusMenu;

@end
