/*
 ShiftIt: Window Organizer for OSX
 Copyright (c) 2010-2011 Filip Krikava
 
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

@interface PreferencesWindowController : NSWindowController {
 @private
	NSString *selectedTabIdentifier_;
    NSString *debugLoggingFile_;
	
    IBOutlet NSTabView *tabView_;
	IBOutlet NSTextField *versionLabel_;

    IBOutlet NSButtonCell *showMenuIcon;

    IBOutlet NSTableView *hotkeysView_;
    IBOutlet NSTableColumn *hotkeyLabelColumn_;
    IBOutlet NSTableColumn *hotkeyColumn_;
}

@property BOOL shouldStartAtLogin;
@property BOOL debugLogging;
@property(copy) NSString *debugLoggingFile;

-(void)updateRecorderCombos;
-(IBAction)showPreferences:(id)sender;
-(IBAction)revertDefaults:(id)sender;
-(IBAction)reportIssue:(id)sender;
-(IBAction)revealLogFileInFinder:(id)sender;
-(IBAction)showMenuBarIconAction:(id)sender;

@end
