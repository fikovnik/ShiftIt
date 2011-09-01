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
#import "SimpleShiftItAction.h"
#import "DefaultShiftItActions.h"
#import "PreferencesWindowController.h"
#import "ShiftItWindowManager.h"
#import "AXWindowDriver.h"
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
NSString *const kMarginsEnabledPrefKey =  @"marginsEnabled";
NSString *const kLeftMarginPrefKey = @"leftMargin";
NSString *const kTopMarginPrefKey = @"topMargin";
NSString *const kBottomMarginPrefKey = @"bottomMargin";
NSString *const kRightMarginPrefKey = @"rightMargin";
NSString *const kSizeDeltaTypePrefKey = @"sizeDeltaType";
NSString *const kFixedSizeWidthDeltaPrefKey = @"fixedSizeWidthDelta";
NSString *const kFixedSizeHeightDeltaPrefKey = @"fixedSizeHeightDelta";
NSString *const kWindowSizeDeltaPrefKey = @"windowSizeDelta";
NSString *const kScreenSizeDeltaPrefKey = @"screenSizeDelta";
NSString *const kIncludeDrawersPrefKey = @"includeDrawers";
NSString *const kNumberOfTriesPrefKey = @"numberOfTries";

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

NSInteger const kWindowManagerFailureErrorCode = 20101;
NSInteger const kAXFailureErrorCode = 20102;
NSInteger const kShiftItActionFaiureErrorCode = 20103;

const CFAbsoluteTime kMinimumTimeBetweenActionInvocations = 1/3; // in seconds

NSDictionary *allShiftActions = nil;

@interface ShiftItAppDelegate (Private)

- (void)initializeActions_;
- (void)updateMenuBarIcon_;
- (void)firstLaunch_;
- (void)invokeShiftItActionByIdentifier_:(NSString *)identifier;
- (void)updateStatusMenuShortcutForAction_:(AbstractShiftItAction *)action keyCode:(NSInteger)keyCode modifiers:(NSUInteger)modifiers;

- (void)handleShowPreferencesRequest_:(NSNotification *) notification; 
- (void) shiftItActionHotKeyChanged_:(NSNotification *) notification;
- (void)handleActionsStateChangeRequest_:(NSNotification *) notification;

- (IBAction)shiftItMenuAction_:(id)sender;
@end


@implementation ShiftItAppDelegate

+ (void) initialize {
	// register defaults - we assume that the installation is correct
	NSString *path = FMTGetMainBundleResourcePath(kShiftItUserDefaults, @"plist");
	NSDictionary *d = [NSDictionary dictionaryWithContentsOfFile:path];
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults registerDefaults:d];	
}

- (id)init{
	if(![super init]){
		return nil;
	}
	
	NSString *iconPath = FMTGetMainBundleResourcePath(kSIIconName, @"png");
	statusMenuItemIcon_ = [[NSImage alloc] initWithContentsOfFile:iconPath];
	allHotKeys_ = [[NSMutableDictionary alloc] init];
	
	beforeNow_ = CFAbsoluteTimeGetCurrent();
	
	return self;
}

- (void) dealloc {
	[statusMenuItemIcon_ release];
	[allShiftActions release];
    [windowManager_ release];
    
	[super dealloc];
}

- (void) firstLaunch_  {
	FMTLogInfo(@"First run");		
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
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	FMTLogDebug(@"Starting up ShiftIt...");
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
	// check preferences
	BOOL hasStartedBefore = [defaults boolForKey:kHasStartedBeforePrefKey];
	
	if (!hasStartedBefore) {
		// make sure this was the only time
		[defaults setBool:YES forKey:@"hasStartedBefore"];
		[defaults synchronize];
        
		[self firstLaunch_];
	}
    
	if (!AXAPIEnabled()){
        int ret = NSRunAlertPanel (@"UI Element Inspector requires that the Accessibility API be enabled.  Please \"Enable access for assistive devices and try again\".", @"", @"OK", @"Cancel",NULL);
        switch (ret) {
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
	windowManager_ = [[ShiftItWindowManager alloc] initWithDriver:[[[AXWindowDriver alloc] init] autorelease]];
	
	[self initializeActions_];
	[self updateMenuBarIcon_];
	
	NSUserDefaultsController *userDefaultsController = [NSUserDefaultsController sharedUserDefaultsController];
	[userDefaultsController addObserver:self forKeyPath:FMTStr(@"values.%@",kShowMenuPrefKey) options:0 context:self];
	
	for (AbstractShiftItAction *action in [allShiftActions allValues]) {
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
	FMTLogInfo(@"Shutting down ShiftIt...");
	
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

- (void)updateStatusMenuShortcutForAction_:(AbstractShiftItAction *)action keyCode:(NSInteger)keyCode modifiers:(NSUInteger)modifiers {
	FMTAssertNotNil(action);
	FMTLogDebug(@"updateStatusMenuShortcutForAction_:%@ keyCode:%ld modifiers:%ld", [action identifier], keyCode, modifiers);
    
	NSMenuItem *menuItem = [statusMenu_ itemWithTag:kSIMenuUITagPrefix+[action uiTag]];
	FMTAssertNotNil(menuItem);
	
	[menuItem setTitle:[action label]];
	[menuItem setRepresentedObject:[action identifier]];
	[menuItem setAction:@selector(shiftItMenuAction_:)];
	
	if (keyCode != -1) {
		NSString *keyCodeString = SRStringForKeyCode(keyCode);
		if (!keyCodeString) {
			FMTLogInfo(@"Unable to get string representation for a key code: %ld", keyCode);
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

    // TODO: this is ugly but just temp
    SimpleShiftItAction *action = nil;
    
    #define REGISTER_ACTION(dict, a) \
    action = (a); \
    [(dict) setObject:action forKey:[action identifier]];
    
    REGISTER_ACTION(dict, [[SimpleShiftItAction alloc] initWithIdentifier:@"left" label:@"Left" uiTag:1 block:shiftItLeft]);
    REGISTER_ACTION(dict, [[SimpleShiftItAction alloc] initWithIdentifier:@"right" label:@"Right" uiTag:2 block:shiftItRight]);
    REGISTER_ACTION(dict, [[SimpleShiftItAction alloc] initWithIdentifier:@"top" label:@"Top" uiTag:3 block:shiftItTop]);
    REGISTER_ACTION(dict, [[SimpleShiftItAction alloc] initWithIdentifier:@"bottom" label:@"Bottom" uiTag:4 block:shiftItBottom]);
    REGISTER_ACTION(dict, [[SimpleShiftItAction alloc] initWithIdentifier:@"tl" label:@"Top Left" uiTag:5 block:shiftItTopLeft]);
    REGISTER_ACTION(dict, [[SimpleShiftItAction alloc] initWithIdentifier:@"tr" label:@"Top Right" uiTag:6 block:shiftItTopRight]);
    REGISTER_ACTION(dict, [[SimpleShiftItAction alloc] initWithIdentifier:@"bl" label:@"Bottom Left" uiTag:7 block:shiftItBottomLeft]);
    REGISTER_ACTION(dict, [[SimpleShiftItAction alloc] initWithIdentifier:@"br" label:@"Bottom Right" uiTag:8 block:shiftItBottomRight]);
    REGISTER_ACTION(dict, [[SimpleShiftItAction alloc] initWithIdentifier:@"center" label:@"Center" uiTag:9 block:shiftItCenter]);
    REGISTER_ACTION(dict, [[ToggleZoomShiftItAction alloc] initWithIdentifier:@"zoom" label:@"Toggle Zoom" uiTag:10]);
    REGISTER_ACTION(dict, [[SimpleShiftItAction alloc] initWithIdentifier:@"maximize" label:@"Maximize" uiTag:11 block:shiftItFullScreen]);
    REGISTER_ACTION(dict, [[ToggleFullScreenShiftItAction alloc] initWithIdentifier:@"fullScreen" label:@"Toggle Full Screen" uiTag:12]);
    REGISTER_ACTION(dict, [[SimpleShiftItAction alloc] initWithIdentifier:@"increase" label:@"Increase" uiTag:13 block:shiftItIncrease]);
    REGISTER_ACTION(dict, [[SimpleShiftItAction alloc] initWithIdentifier:@"reduce" label:@"Reduce" uiTag:14 block:shiftItReduce]);
	
	allShiftActions = [[NSDictionary dictionaryWithDictionary:dict] retain];
}

- (void)handleShowPreferencesRequest_:(NSNotification *) notification {
	[self showPreferences:self];
}

- (void)handleActionsStateChangeRequest_:(NSNotification *) notification {
	NSString *name = [notification name];
	
	if ([name isEqualToString:kDidFinishEditingHotKeysPrefNotification]) {
		@synchronized(self) {
			paused_ = NO;
			FMTLogDebug(@"Resuming actions");
		}
	} else if ([name isEqualToString:kDidStartEditingHotKeysPrefNotification]) {
		@synchronized(self) {
			paused_ = YES;
			FMTLogDebug(@"Pausing actions");
		}		
	}
	
}

- (void) shiftItActionHotKeyChanged_:(NSNotification *) notification {
	NSDictionary *userInfo = [notification userInfo];
    
	NSString *identifier = [userInfo objectForKey:kActionIdentifierKey];
	NSInteger keyCode = [[userInfo objectForKey:kHotKeyKeyCodeKey] integerValue];
	NSUInteger modifiers = [[userInfo objectForKey:kHotKeyModifiersKey] longValue];
	
	FMTLogDebug(@"Updating action %@ hotKey: keyCode=%ld modifiers=%ld", identifier, keyCode, modifiers);
	
	AbstractShiftItAction *action = [allShiftActions objectForKey:identifier];
	FMTAssertNotNil(action);
	
	FMTHotKey *newHotKey = [[FMTHotKey alloc] initWithKeyCode:keyCode modifiers:modifiers];
	
	FMTHotKey *hotKey = [allHotKeys_ objectForKey:identifier];
	if (hotKey) {
		if ([hotKey isEqualTo:newHotKey]) {
			FMTLogDebug(@"Hot key is the same");
			return;
		}
		
		FMTLogDebug(@"Unregistering old hot key: %@ for shiftIt action %@", hotKey, identifier);
		[hotKeyManager_ unregisterHotKey:hotKey];
		[allHotKeys_ removeObjectForKey:identifier];
	}
	
	if (keyCode == -1) { // no key
		FMTLogDebug(@"No hot key");
	} else {
		FMTLogDebug(@"Registering new hot key: %@ for shiftIt action %@", newHotKey, identifier);
		[hotKeyManager_ registerHotKey:newHotKey handler:@selector(invokeShiftItActionByIdentifier_:) provider:self userData:identifier];
		[allHotKeys_ setObject:newHotKey forKey:identifier];
	}
	
	// update menu
	[self updateStatusMenuShortcutForAction_:action keyCode:keyCode modifiers:modifiers];
	
	if ([notification object] != self) {
		// save to user preferences
		FMTLogDebug(@"Updating user preferences with new hot key: %@ for shiftIt action %@", newHotKey, identifier);
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		[defaults setInteger:keyCode forKey:KeyCodePrefKey(identifier)];
		[defaults setInteger:modifiers forKey:ModifiersPrefKey(identifier)];
		[defaults synchronize];
	}
}

- (void) invokeShiftItActionByIdentifier_:(NSString *)identifier {
	@synchronized(self) {
		if (paused_) {
			FMTLogDebug(@"The functionality is temporarly paused");
			return ;
		}
        
		CFAbsoluteTime now = CFAbsoluteTimeGetCurrent();
		
		// since now can be actually smaller than beforeNow_ due to sync
		// we just drop it anyway and hope next time we have more luck
		if (now > beforeNow_ && now - beforeNow_ < kMinimumTimeBetweenActionInvocations) {
			// drop it - too soon new request
			// we need to give the AXUI and others some time to recover :)
			// otherwise some weird results are experienced
			return ;
		} else {
			beforeNow_ = now;
		}
		
		AbstractShiftItAction *action = [allShiftActions objectForKey:identifier];
		FMTAssertNotNil(action);
		
		FMTLogInfo(@"Invoking action: %@", identifier);
		NSError *error = nil;
		if (![windowManager_ executeAction:action error:&error]) {
			FMTLogError(@"ShiftIt action: %@ failed: %@", [action identifier], FMTGetErrorDescription(error));
		}
	}
}

- (IBAction)shiftItMenuAction_:(id)sender {
	FMTAssertNotNil(sender);
	FMTAssert([sender isKindOfClass:[NSMenuItem class]], @"Invalid type of sender: %@", [sender class]);
	
	NSString *identifier = [sender representedObject];
	FMTAssertNotNil(identifier);
	
	FMTLogDebug(@"ShitIt action activated from menu: %@", identifier);	
    
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

inline NSError* SICreateErrorWithCause(NSString *localizedDescription, NSInteger errorCode, NSError *cause) {
	FMTAssertNotNil(localizedDescription);
	FMTAssertNotNil(cause);
	
	NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithCapacity:1];
	[userInfo setObject:localizedDescription forKey:NSLocalizedDescriptionKey];
	[userInfo setObject:cause forKey:NSUnderlyingErrorKey];
	
	NSError *error = [NSError errorWithDomain:SIErrorDomain code:errorCode userInfo:userInfo];	
	return error;    
}