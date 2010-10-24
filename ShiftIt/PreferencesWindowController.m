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
#import "FMTUtils.h"

NSString *const kKeyCodePrefKeySuffix = @"KeyCode";
NSString *const kModifiersPrefKeySuffix = @"Modifiers";

NSString *const kDidFinishEditingHotKeysPrefNotification = @"kEnableActionsRequestNotification";
NSString *const kDidStartEditingHotKeysPrefNotification = @"kDisableActionsRequestNotification";
NSString *const kHotKeyChangedNotification = @"kHotKeyChangedNotification";
NSString *const kActionIdentifierKey = @"kActionIdentifierKey";
NSString *const kHotKeyKeyCodeKey = @"kHotKeyKeyCodeKey";
NSString *const kHotKeyModifiersKey = @"kHotKeyModifiersKey";

NSInteger const kSISRUITagPrefix = 1000;

NSString *const kHotKeysTabViewItemIdentifier = @"hotKeys";

@interface PreferencesWindowController(Private)

- (void)windowMainStatusChanged_:(NSNotification *)notification;

@end


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

	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	[notificationCenter addObserver:self selector:@selector(windowMainStatusChanged_:) name:NSWindowDidResignMainNotification object:[self window]];
	[notificationCenter addObserver:self selector:@selector(windowMainStatusChanged_:) name:NSWindowDidBecomeMainNotification object:[self window]];
	
	[self updateRecorderCombos];
}

-(IBAction)showPreferences:(id)sender{
    [[self window] center];
    [NSApp activateIgnoringOtherApps:YES];
    [[self window] makeKeyAndOrderFront:sender];    
}

-(IBAction)revertDefaults:(id)sender {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

	NSString *path = FMTGetMainBundleResourcePath(kShiftItUserDefaults, @"plist");
	NSDictionary *initialDefaults = [NSDictionary dictionaryWithContentsOfFile:path];
	[defaults registerDefaults:initialDefaults];

	for (ShiftItAction *action in [allShiftActions allValues]) {
		NSString *identifier = [action identifier];
		
		NSNumber *n = nil;

		n = [initialDefaults objectForKey:KeyCodePrefKey(identifier)];
		[defaults setInteger:[n integerValue] forKey:KeyCodePrefKey(identifier)];
		
		n = [initialDefaults objectForKey:ModifiersPrefKey(identifier)];
		[defaults setInteger:[n integerValue] forKey:ModifiersPrefKey(identifier)];
	}
	
	[defaults synchronize];
	
	// normally this won't be necessary since there could be an observer 
	// looking at changes in the user defaults values itself, but since there is
	// unfortunatelly 2 defaults for one key this won't work well
	[self updateRecorderCombos];
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

#pragma mark TabView delegate methods

- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem {
	if ([selectedTabIdentifier_ isEqualTo:kHotKeysTabViewItemIdentifier]) {
		[[NSNotificationCenter defaultCenter] postNotificationName:kDidStartEditingHotKeysPrefNotification object:nil];
	} else {
		[[NSNotificationCenter defaultCenter] postNotificationName:kDidFinishEditingHotKeysPrefNotification object:nil];
	}
}

#pragma mark Notification handling methods

- (void)windowMainStatusChanged_:(NSNotification *)notification {
	NSString *name = [notification name];

	if ([name isEqualTo:NSWindowDidBecomeMainNotification] && [selectedTabIdentifier_ isEqualTo:kHotKeysTabViewItemIdentifier]) {
		[[NSNotificationCenter defaultCenter] postNotificationName:kDidStartEditingHotKeysPrefNotification object:nil];
	} else if ([name isEqualTo:NSWindowDidResignMainNotification]) {
		[[NSNotificationCenter defaultCenter] postNotificationName:kDidFinishEditingHotKeysPrefNotification object:nil];
	}
}

@end
