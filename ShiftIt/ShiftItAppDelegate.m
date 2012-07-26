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

#import "ShiftItAppDelegate.h"
#import "ShiftIt.h"
#import "ShiftItAction.h"
#import "DefaultShiftItActions.h"
#import "PreferencesWindowController.h"
#import "WindowSizer.h"
#import "FMTLoginItems.h"
#import "FMTHotKey.h"
#import "FMTHotKeyManager.h"
#import "FMTUtils.h"
#import "FMTDefines.h"

NSString *const kShiftItAppBundleId = @"org.shiftitapp.ShiftIt";

// the name of the plist file containing the preference defaults
NSString *const kShiftItUserDefaults = @"ShiftIt-defaults";

// preferencs
NSString *const kHasStartedBeforePrefKey = @"hasStartedBefore";
NSString *const kShowMenuPrefKey = @"shiftItshowMenu";

// notifications
NSString *const kShowPreferencesRequestNotification = @"org.shiftitapp.shiftit.notifiactions.showPreferences";

// icon
NSString *const kSIIconName = @"ShiftIt-menuIcon";
NSString *const kSIMenuItemTitle = @"Shift";

// the size that should be reserved for the menu item in the system menu in px
NSInteger const kSIMenuItemSize = 30;

NSInteger const kSIMenuUITagPrefix = 2000;

// error related
NSString *const SIErrorDomain = @"org.shiftitapp.shiftit.ErrorDomain";
NSInteger const kUnableToGetActiveWindowErrorCode = 20100;
NSInteger const kUnableToChangeWindowPositionErrorCode = 20101;
NSInteger const kUnableToGetWindowGeometryErrorCode = 20102;
NSInteger const kUnableToChangeWindowSizeErrorCode = 20102;

NSDictionary *allShiftActions = nil;

@interface ShiftItAppDelegate (Private)

- (void)initializeActions_;
- (void)updateMenuBarIcon_;
- (void)firstLaunch_;
- (void)invokeShiftItActionByIdentifier_:(NSString *)identifier;
- (void)updateStatusMenuShortcutForAction_:(ShiftItAction *)action keyCode:(NSInteger)keyCode modifiers:(NSUInteger)modifiers;

- (void)handleShowPreferencesRequest_:(NSNotification *) notification; 
- (void) shiftItActionHotKeyChanged_:(NSNotification *) notification;
- (void)handleActionsStateChangeRequest_:(NSNotification *) notification;

- (IBAction)shiftItMenuAction_:(id)sender;
@end


@implementation ShiftItAppDelegate

- (id)init{
	if(![super init]){
		return nil;
	}
	
	statusMenuItemIcon_ = [NSImage imageNamed:kSIIconName];
	allHotKeys_ = [[NSMutableDictionary alloc] init];
	
	return self;
}

- (void) dealloc {
	[statusMenuItemIcon_ release];
	[allShiftActions release];
	
	[super dealloc];
}

- (void) firstLaunch_  {
	FMTDevLog(@"First run");

	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		
	// ask to start it automatically - make sure it is not there
	
	// TODO: refactor this so it shares the code from the pref controller
	FMTLoginItems *loginItems = [FMTLoginItems sharedSessionLoginItems];
	NSString *appPath = [[NSBundle mainBundle] bundlePath];
	
	if (![loginItems isInLoginItemsApplicationWithPath:appPath]) {
		int ret = NSRunAlertPanel (@"Start ShiftIt automatically?", @"Would you like to have ShiftIt automatically started at a login time?", @"Yes", @"No",NULL);
		switch (ret){
			case NSAlertDefaultReturn:
				// do it!
				[loginItems toggleApplicationInLoginItemsWithPath:appPath enabled:YES];
				break;
			default:
				break;
		}		
	}
	
	// make sure this was the only time
	[defaults setBool:YES forKey:@"hasStartedBefore"];
	[defaults synchronize];
	
}
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	FMTDevLog(@"Starting up ShiftIt...");
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults synchronize];

	// check preferences
	BOOL hasStartedBefore = [defaults boolForKey:kHasStartedBeforePrefKey];
	
	if (!hasStartedBefore) {
		[self firstLaunch_];
	}

	// register defaults - we assume that the installation is correct
	NSString *path = FMTGetMainBundleResourcePath(kShiftItUserDefaults, @"plist");
	NSDictionary *d = [NSDictionary dictionaryWithContentsOfFile:path];
	[defaults registerDefaults:d];
	
	if (!AXAPIEnabled()){
        int ret = NSRunAlertPanel (@"UI Element Inspector requires that the Accessibility API be enabled.  Please \"Enable access for assistive devices and try again\".", @"", @"OK", @"Cancel",NULL);
        switch (ret){
            case NSAlertDefaultReturn:
                [[NSWorkspace sharedWorkspace] openFile:@"/System/Library/PreferencePanes/UniversalAccessPref.prefPane"];
				[NSApp terminate:self];
				
				return;
            case NSAlertAlternateReturn:
                [NSApp terminate:self];
                
				return;
            default:
                break;
        }
    }
	
	hotKeyManager_ = [FMTHotKeyManager sharedHotKeyManager];
	windowSizer_ = [WindowSizer sharedWindowSize];
	
	[self initializeActions_];
	[self updateMenuBarIcon_];
	
	NSUserDefaultsController *userDefaultsController = [NSUserDefaultsController sharedUserDefaultsController];
	[userDefaultsController addObserver:self forKeyPath:FMTStr(@"values.%@",kShowMenuPrefKey) options:0 context:self];
	
	for (ShiftItAction *action in [allShiftActions allValues]) {
		NSString *identifier = [action identifier];
		
		NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithCapacity:3];
		[userInfo setObject:[action identifier]  forKey:kActionIdentifierKey];
		[userInfo setObject:[NSNumber numberWithInt:[defaults integerForKey:KeyCodePrefKey(identifier)]] forKey:kHotKeyKeyCodeKey];
		[userInfo setObject:[NSNumber numberWithInt:[defaults integerForKey:ModifiersPrefKey(identifier)]] forKey:kHotKeyModifiersKey];
		
		NSNotification *notification = [NSNotification notificationWithName:kHotKeyChangedNotification object:self userInfo:userInfo];
		[self shiftItActionHotKeyChanged_:notification];
	}

	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	[notificationCenter addObserver:self selector:@selector(shiftItActionHotKeyChanged_:) name:kHotKeyChangedNotification object:nil];
	[notificationCenter addObserver:self selector:@selector(handleActionsStateChangeRequest_:) name:kDidFinishEditingHotKeysPrefNotification object:nil];
	[notificationCenter addObserver:self selector:@selector(handleActionsStateChangeRequest_:) name:kDidStartEditingHotKeysPrefNotification object:nil];
	
	notificationCenter = [NSDistributedNotificationCenter defaultCenter];
	[notificationCenter addObserver:self selector:@selector(handleShowPreferencesRequest_:) name:kShowPreferencesRequestNotification object:nil];
}

- (void) applicationWillTerminate:(NSNotification *)aNotification {
	FMTDevLog(@"Shutting down ShiftIt...");
	
	// unregister hotkeys
	for (FMTHotKey *hotKey in [allHotKeys_ allValues]) {
		[hotKeyManager_ unregisterHotKey:hotKey];
	}
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows: (BOOL)flag{	
	if(flag==NO){
		[self showPreferences:nil];
	}
	return YES;
} 

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
	if([FMTStr(@"values.%@",kShowMenuPrefKey) isEqualToString:keyPath]) {
		[self updateMenuBarIcon_];
	} 
}

- (void) updateMenuBarIcon_ {
	BOOL showIconInMenuBar = [[NSUserDefaults standardUserDefaults] boolForKey:kShowMenuPrefKey];
	NSStatusBar * statusBar = [NSStatusBar systemStatusBar];
	
	if(showIconInMenuBar) {
		if(!statusItem_) {
			statusItem_ = [[statusBar statusItemWithLength:kSIMenuItemSize] retain];
			[statusItem_ setMenu:statusMenu_];
			if (statusMenuItemIcon_) {
				[statusItem_ setImage:statusMenuItemIcon_];
			} else {
				[statusItem_ setTitle:kSIMenuItemTitle];
			}
			[statusItem_ setHighlightMode:YES];
		}
	} else {
		[statusBar removeStatusItem:statusItem_];
		[statusItem_ autorelease];
		statusItem_ = nil;
	}
}

- (IBAction)showPreferences:(id)sender {
    if (!preferencesController_) {
        preferencesController_ = [[PreferencesWindowController alloc]init];
    }

    [preferencesController_ showPreferences:sender];
    [NSApp activateIgnoringOtherApps:YES];
}

- (void)updateStatusMenuShortcutForAction_:(ShiftItAction *)action keyCode:(NSInteger)keyCode modifiers:(NSUInteger)modifiers {
	FMTAssertNotNil(action);
	FMTDevLog(@"updateStatusMenuShortcutForAction_:%@ keyCode:%d modifiers:%ld", [action identifier], keyCode, modifiers);

	NSMenuItem *menuItem = [statusMenu_ itemWithTag:kSIMenuUITagPrefix+[action uiTag]];
	FMTAssertNotNil(menuItem);
	
	[menuItem setTitle:[action label]];
	[menuItem setRepresentedObject:[action identifier]];
	[menuItem setAction:@selector(shiftItMenuAction_:)];
	
	if (keyCode != -1) {
		NSString *keyCodeString = SRStringForKeyCode(keyCode);
		if (!keyCodeString) {
			FMTDevLog(@"Unable to get string representation for a key code: %ld", keyCode);
			keyCodeString = @"";
		}
		[menuItem setKeyEquivalent:[keyCodeString lowercaseString]];
		[menuItem setKeyEquivalentModifierMask:modifiers];
	} else {
		[menuItem setKeyEquivalent:@""];
		[menuItem setKeyEquivalentModifierMask:0];
	}
}

- (void) initializeActions_ {
	FMTAssert(allShiftActions == nil, @"Actions have been already initialized");
	
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	
	ShiftItAction *left = [[ShiftItAction alloc] initWithIdentifier:@"left" label:@"Left" uiTag:1 action:&ShiftIt_Left];
	[dict setObject:left forKey:[left identifier]];
	ShiftItAction *right = [[ShiftItAction alloc] initWithIdentifier:@"right" label:@"Right" uiTag:2 action:&ShiftIt_Right];
	[dict setObject:right forKey:[right identifier]];
	ShiftItAction *top = [[ShiftItAction alloc] initWithIdentifier:@"top" label:@"Top" uiTag:3 action:&ShiftIt_Top];
	[dict setObject:top forKey:[top identifier]];
	ShiftItAction *bottom = [[ShiftItAction alloc] initWithIdentifier:@"bottom" label:@"Bottom" uiTag:4 action:&ShiftIt_Bottom];
	[dict setObject:bottom forKey:[bottom identifier]];
	ShiftItAction *tl = [[ShiftItAction alloc] initWithIdentifier:@"tl" label:@"Top Left" uiTag:5 action:&ShiftIt_TopLeft];
	[dict setObject:tl forKey:[tl identifier]];
	ShiftItAction *tr = [[ShiftItAction alloc] initWithIdentifier:@"tr" label:@"Top Right" uiTag:6 action:&ShiftIt_TopRight];
	[dict setObject:tr forKey:[tr identifier]];
	ShiftItAction *bl = [[ShiftItAction alloc] initWithIdentifier:@"bl" label:@"Bottom Left" uiTag:7 action:&ShiftIt_BottomLeft];
	[dict setObject:bl forKey:[bl identifier]];
	ShiftItAction *br = [[ShiftItAction alloc] initWithIdentifier:@"br" label:@"Bottom Right" uiTag:8 action:&ShiftIt_BottomRight];
	[dict setObject:br forKey:[br identifier]];
	ShiftItAction *fullscreen = [[ShiftItAction alloc] initWithIdentifier:@"fullscreen" label:@"Full Screen" uiTag:9 action:&ShiftIt_FullScreen];
	[dict setObject:fullscreen forKey:[fullscreen identifier]];
	ShiftItAction *center = [[ShiftItAction alloc] initWithIdentifier:@"center" label:@"Center" uiTag:10 action:&ShiftIt_Center];
	[dict setObject:center forKey:[center identifier]];
	
	allShiftActions = [[NSDictionary dictionaryWithDictionary:dict] retain];
}

- (void)handleShowPreferencesRequest_:(NSNotification *) notification {
	[self showPreferences:self];
}

- (void)handleActionsStateChangeRequest_:(NSNotification *) notification {
	NSString *name = [notification name];
	
	if ([name isEqualTo:kDidFinishEditingHotKeysPrefNotification]) {
		@synchronized(self) {
			paused_ = NO;
			FMTDevLog(@"Resuming actions");
		}
	} else if ([name isEqualTo:kDidStartEditingHotKeysPrefNotification]) {
		@synchronized(self) {
			paused_ = YES;
			FMTDevLog(@"Pausing actions");
		}		
	}
	
}

- (void) shiftItActionHotKeyChanged_:(NSNotification *) notification {
	NSDictionary *userInfo = [notification userInfo];

	NSString *identifier = [userInfo objectForKey:kActionIdentifierKey];
	NSInteger keyCode = [[userInfo objectForKey:kHotKeyKeyCodeKey] integerValue];
	NSUInteger modifiers = [[userInfo objectForKey:kHotKeyModifiersKey] longValue];
	
	FMTDevLog(@"Updating action %@ hotKey: keyCode=%d modifiers=%ld", identifier, keyCode, modifiers);
	
	ShiftItAction *action = [allShiftActions objectForKey:identifier];
	FMTAssertNotNil(action);
	
	FMTHotKey *newHotKey = [[FMTHotKey alloc] initWithKeyCode:keyCode modifiers:modifiers];
	
	FMTHotKey *hotKey = [allHotKeys_ objectForKey:identifier];
	if (hotKey) {
		if ([hotKey isEqualTo:newHotKey]) {
			FMTDevLog(@"Hot key is the same");
			return;
		}
		
		FMTDevLog(@"Unregistering old hot key: %@ for shiftIt action %@", hotKey, identifier);
		[hotKeyManager_ unregisterHotKey:hotKey];
		[allHotKeys_ removeObjectForKey:identifier];
	}
	
	if (keyCode == -1) { // no key
		FMTDevLog(@"No hot key");
	} else {
		FMTDevLog(@"Registering new hot key: %@ for shiftIt action %@", newHotKey, identifier);
		[hotKeyManager_ registerHotKey:newHotKey handler:@selector(invokeShiftItActionByIdentifier_:) provider:self userData:identifier];
		[allHotKeys_ setObject:newHotKey forKey:identifier];
	}
	
	// update menu
	[self updateStatusMenuShortcutForAction_:action keyCode:keyCode modifiers:modifiers];
	
	if ([notification object] != self) {
		// save to user preferences
		FMTDevLog(@"Updating user preferences with new hot key: %@ for shiftIt action %@", newHotKey, identifier);
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		[defaults setInteger:keyCode forKey:KeyCodePrefKey(identifier)];
		[defaults setInteger:modifiers forKey:ModifiersPrefKey(identifier)];
		[defaults synchronize];
	}
}

- (void) invokeShiftItActionByIdentifier_:(NSString *)identifier {
	@synchronized(self) {
		if (paused_) {
			FMTDevLog(@"The functionality is temporarly paused");
			return ;
		}
	}
	
	ShiftItAction *action = [allShiftActions objectForKey:identifier];
	FMTAssertNotNil(action);
	
	FMTDevLog(@"Invoking action: %@", identifier);
	NSError *error = nil;
	[windowSizer_ shiftFocusedWindowUsing:action error:&error];
	if (error) {
		NSLog(@"ShiftIt action: %@ failed: %@", [action identifier], FMTGetErrorDescription(error));
	}	
}

- (IBAction)shiftItMenuAction_:(id)sender {
	FMTAssertNotNil(sender);
	FMTAssert([sender isKindOfClass:[NSMenuItem class]], @"Invalid type of sender: %@", [sender class]);
	
	NSString *identifier = [sender representedObject];
	FMTAssertNotNil(identifier);
	
	FMTDevLog(@"ShitIt action activated from menu: %@", identifier);	

	[self invokeShiftItActionByIdentifier_:identifier];
}

		 
@end

inline NSError* SICreateError(NSString *localizedDescription, NSInteger errorCode) {
	FMTAssertNotNil(localizedDescription);
	
	NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithCapacity:1];
	[userInfo setObject:localizedDescription forKey:NSLocalizedDescriptionKey];
	
	NSError *error = [NSError errorWithDomain:SIErrorDomain code:errorCode userInfo:userInfo];	
	return error;
}