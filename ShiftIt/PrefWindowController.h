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
#include "SIHotKey.h"
#include "hKController.h"

@interface PrefWindowController : NSWindowController {
    hKController *hkContObject;
    IBOutlet NSButton * _openAtLogin;
    IBOutlet NSTabView * tabView;
	
	NSTextField * topField;
	NSTextField * bottomField;
	NSTextField * leftField;
	NSTextField * rightField;
	NSTextField * tlField;
	NSTextField * trField;
	NSTextField * blField;
	NSTextField * brField;
	NSTextField * fullScreenField;
	NSTextField * centerField;
	NSButton *cancelHotkeyButton;
	NSArray *textFieldArray;
	
	IBOutlet NSMatrix *hotKeyButtonMatrix;
	NSMutableString *modifiersString;
	NSInteger buttonPressed;
	NSMenu *statusMenu;
	NSString *oldHotkeyString;

}

-(IBAction)savePreferences:(id)sender;
-(IBAction)showPreferences:(id)sender;

-(IBAction)changeHotkey:(id)sender;
- (IBAction)cancelHotkey:(id)sender;

-(NSMutableString *)modifierKeysStringForFlags:(NSUInteger)modifierFlags;
-(void)disableButtons;
-(void)enableButtons;
-(void)updateTextFields;

@property (assign) IBOutlet NSTextField * topField;
@property (assign) IBOutlet NSTextField * bottomField;
@property (assign) IBOutlet NSTextField * leftField;
@property (assign) IBOutlet NSTextField * rightField;
@property (assign) IBOutlet NSTextField * tlField;
@property (assign) IBOutlet NSTextField * trField;
@property (assign) IBOutlet NSTextField * blField;
@property (assign) IBOutlet NSTextField * brField;
@property (assign) IBOutlet NSTextField * fullScreenField;
@property (assign) IBOutlet NSTextField * centerField;
@property (assign) IBOutlet NSButton *cancelHotkeyButton;
@property (nonatomic, retain) NSArray *textFieldArray;

@property (nonatomic, retain) NSMatrix *hotKeyButtonMatrix;
@property (nonatomic, retain) NSMutableString *modifiersString;
@property (nonatomic) NSInteger buttonPressed;
@property (nonatomic, retain) NSMenu *statusMenu;
@property (nonatomic, retain) NSString *oldHotkeyString;

@end
