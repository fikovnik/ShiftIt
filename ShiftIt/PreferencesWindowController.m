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

#import "PreferencesWindowController.h"
#import "ShiftIt.h"
#import "ShiftItAction.h"
#import "FMTLoginItems.h"
#import "FMTDefines.h"

NSString *const kShiftItAppBundleId = @"org.shiftitapp.shiftit";

NSString *const kKeyCodePrefKeySuffix = @"KeyCode";
NSString *const kModifiersPrefKeySuffix = @"Modifiers";

NSString *const kHotKeyChangedNotification = @"kHotKeyChangedNotification";
NSString *const kActionIdentifierKey = @"kActionIdentifierKey";
NSString *const kHotKeyKeyCodeKey = @"kHotKeyKeyCodeKey";
NSString *const kHotKeyModifiersKey = @"kHotKeyModifiersKey";

NSInteger const kSISRUITagPrefix = 1000;

@implementation PreferencesWindowController

@dynamic shouldStartAtLogin;

-(id)init{
    if (![super initWithWindowNibName:@"PreferencesWindow"]) {
		return nil;
    }
	
    return self;
}

-(BOOL)acceptsFirstResponder{
	return YES;
}

-(void)awakeFromNib {
    [tabView_ selectTabViewItemAtIndex:0];

	NSString *versionString = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
	[versionLabel_ setStringValue:versionString];

	[self updateRecorderCombos];
}

-(IBAction)showPreferences:(id)sender{
    [[self window] center];
    [NSApp activateIgnoringOtherApps:YES];
    [[self window] makeKeyAndOrderFront:sender];    
}

#pragma mark shouldStartAtLogin dynamic property methods

- (BOOL)shouldStartAtLogin {
	NSString *path = [[NSBundle mainBundle] bundlePath];
	return [[FMTLoginItems sharedSessionLoginItems] isInLoginItemsApplicationWithPath:path];
}

- (void)setShouldStartAtLogin:(BOOL)flag {
	FMTDevLog(@"ShiftIt should start at login: %d", flag);

	NSString *path = [[NSBundle mainBundle] bundlePath];
	[[FMTLoginItems sharedSessionLoginItems] toggleApplicationInLoginItemsWithPath:path enabled:flag];
}

#pragma mark Shortcut Recorder methods

// TODO: make sure user does not regsiter the same shortcuts
// TODO: disable hotkeys while setting shortcuts

- (void)shortcutRecorder:(SRRecorderControl *)recorder keyComboDidChange:(KeyCombo)newKeyCombo{
	NSInteger tag = [recorder tag] - kSISRUITagPrefix;
	
	ShiftItAction *action = nil;
	for (action in [allShiftActions allValues]) {
		if ([action uiTag] == tag) {
			break;
		}
	}
	FMTAssertNotNil(action);
	
	FMTDevLog(@"ShiftIt action %@ hotkey changed: ", [action identifier]);
	
	NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithCapacity:3];
	[userInfo setObject:[action identifier] forKey:kActionIdentifierKey];
	[userInfo setObject:[NSNumber numberWithInt:newKeyCombo.code] forKey:kHotKeyKeyCodeKey];
	[userInfo setObject:[NSNumber numberWithLong:newKeyCombo.flags] forKey:kHotKeyModifiersKey];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:kHotKeyChangedNotification object:self userInfo:userInfo];
}

- (void)updateRecorderCombos {
	NSInteger idx = [tabView_ indexOfTabViewItemWithIdentifier:@"hotKeys"];
	NSView *hotKeysView = [[tabView_ tabViewItemAtIndex:idx] view];
	FMTAssertNotNil(hotKeysView);
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

	for (ShiftItAction *action in [allShiftActions allValues]) {
		SRRecorderControl *recorder = [hotKeysView viewWithTag:kSISRUITagPrefix+[action uiTag]];
		FMTAssertNotNil(recorder);

		NSString *identifier = [action identifier];
		
		KeyCombo combo;
		combo.code = [defaults integerForKey:KeyCodePrefKey(identifier)];
		combo.flags = [defaults integerForKey:ModifiersPrefKey(identifier)];
		[recorder setKeyCombo:combo];		
	}	
}

-(void)dealloc{
	[super dealloc];
}

@end
