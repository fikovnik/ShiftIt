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
 @private
    hKController *hkContObject_;

 	NSArray *recorderCtlArray_;
	
	NSInteger buttonPressed_;
	NSMenu *statusMenu_;
	
	IBOutlet NSButton * openAtLogin_;
    IBOutlet NSTabView * tabView_;
	IBOutlet NSTextField * versionLabel_;
	
	IBOutlet SRRecorderControl *leftRecorderCtrl_;
	IBOutlet SRRecorderControl *rightRecorderCtrl_;
	IBOutlet SRRecorderControl *topRecorderCtrl_;
	IBOutlet SRRecorderControl *bottomRecorderCtrl_;

	IBOutlet SRRecorderControl *tlRecorderCtrl_;
	IBOutlet SRRecorderControl *trRecorderCtrl_;
	IBOutlet SRRecorderControl *blRecorderCtrl_;
	IBOutlet SRRecorderControl *brRecorderCtrl_;

	IBOutlet SRRecorderControl *fullScreenRecorderCtrl_;
	IBOutlet SRRecorderControl *centerRecorderCtrl_;
}

@property (nonatomic, retain) NSArray *recorderCtlArray;
@property (nonatomic) NSInteger buttonPressed;
@property (nonatomic, retain) NSMenu *statusMenu;

-(void)updateRecorderCombos;
-(IBAction)showPreferences:(id)sender;

@end
