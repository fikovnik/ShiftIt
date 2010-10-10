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
#import "FMTHotKey.h"
#import "FMTHotKeyManager.h"
#import "FMTDefines.h"

NSString *const kSIIconName = @"shift-it-menu-icon";
NSString *const kSIIconType = @"png";
NSString *const kSIMenuItemTitle = @"Shift";

// the size that should be reserved for the menu item in the system menu in px
NSInteger const kSIMenuItemSize = 30;

NSInteger const kSIMenuUITagPrefix = 2000;

// error related
NSString *const SIErrorDomain = @"org.shiftitapp.shiftit.ErrorDomain";
NSInteger const kNoFocusWindowRefErrorCode = 20100;
NSInteger const kPositionChangeFailedErrorCode = 20101;
NSInteger const kSizeChangeFailedErrorCode = 20102;

NSDictionary *allShiftActions = nil;

@interface ShiftItAppDelegate (Private)

- (void)initializeActions_;
- (void)updateMenuBarIcon_;
- (void)registerForLogin_;
- (void)invokeShiftItActionByIdentifier_:(NSString *)identifier;
- (void)updateStatusMenuShortcutForAction_:(ShiftItAction *)action keyCode:(NSInteger)keyCode modifiers:(NSUInteger)modifiers;

- (void) shiftItActionHotKeyChanged_:(NSNotification *) notification;

- (IBAction)shiftItMenuAction_:(id)sender;
@end


@implementation ShiftItAppDelegate

- (id)init{
	if(![super init]){
		return nil;
	}
	
	NSString *iconPath = [[NSBundle mainBundle] pathForResource:kSIIconName ofType:kSIIconType];
	statusMenuItemIcon_ = [[NSImage alloc] initWithContentsOfFile:iconPath];
	allHotKeys_ = [[NSMutableDictionary alloc] init];
	
	return self;
}

- (void) dealloc {
	[statusMenuItemIcon_ release];
	[allShiftActions release];
	
	[super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	FMTDevLog(@"Starting up ShiftIt...");

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
	[userDefaultsController addObserver:self forKeyPath:@"values.shiftItshowMenu" options:0 context:self];
	[userDefaultsController addObserver:self forKeyPath:@"values.shiftItstartLogin" options:0 context:self];
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults synchronize];
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
}

- (void) applicationWillTerminate:(NSNotification *)aNotification {
	FMTDevLog(@"Shutting down ShiftIt...");
	
	// unregister hotkeys
	for (FMTHotKey *hotKey in [allHotKeys_ allValues]) {
		[hotKeyManager_ unregisterHotKey:hotKey];
	}
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
	if([keyPath compare:@"values.shiftItshowMenu"] == NSOrderedSame) {
		[self updateMenuBarIcon_];
	} else if ([keyPath compare:@"values.shiftItstartLogin"]== NSOrderedSame) {
		[self registerForLogin_];
	} 
	
}

- (void) updateMenuBarIcon_ {
	BOOL showIconInMenuBar = [[NSUserDefaults standardUserDefaults] boolForKey:@"shiftItshowMenu"];
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

- (void)registerForLogin_{
	BOOL login = [[NSUserDefaults standardUserDefaults] boolForKey:@"shiftItstartLogin"];
    if(login){
        NSString * appPath = [[NSBundle mainBundle] bundlePath];
        
        // This will retrieve the path for the application
        // For example, /Applications/test.app
        CFURLRef url = (CFURLRef)[NSURL fileURLWithPath:appPath]; 
        
        // Create a reference to the shared file list.
        // We are adding it to the current user only.
        // If we want to add it all users, use
        // kLSSharedFileListGlobalLoginItems instead of
        // kLSSharedFileListSessionLoginItems
        LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL,kLSSharedFileListSessionLoginItems, NULL);
        if (loginItems) {
            //Insert an item to the list.
            LSSharedFileListItemRef item = LSSharedFileListInsertItemURL(loginItems,kLSSharedFileListItemLast, NULL, NULL,url, NULL, NULL);
            if (item){
                CFRelease(item);
            }
        }	
        CFRelease(loginItems);
    }else {
        NSString * appPath = [[NSBundle mainBundle] bundlePath];
        
        // This will retrieve the path for the application
        // For example, /Applications/test.app
        CFURLRef url = (CFURLRef)[NSURL fileURLWithPath:appPath]; 
        
        // Create a reference to the shared file list.
        LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL,
                                                                kLSSharedFileListSessionLoginItems, NULL);
        
        if (loginItems) {
            UInt32 seedValue;
            // Retrieve the list of Login Items and cast them to
            // a NSArray so that it will be easier to iterate.
            NSArray  *loginItemsArray = (NSArray *)LSSharedFileListCopySnapshot(loginItems, &seedValue);
            int i = 0;
            for(i ; i< [loginItemsArray count]; i++){
                LSSharedFileListItemRef itemRef = (LSSharedFileListItemRef)[loginItemsArray
                                                                            objectAtIndex:i];
                //Resolve the item with URL
                if (LSSharedFileListItemResolve(itemRef, 0, (CFURLRef*) &url, NULL) == noErr) {
                    NSString * urlPath = [(NSURL*)url path];
                    if ([urlPath compare:appPath] == NSOrderedSame){
                        LSSharedFileListItemRemove(loginItems,itemRef);
                    }
                }
            }
            [loginItemsArray release];
        }
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

	NSString *keyCodeString = SRStringForKeyCode(keyCode);

	NSMenuItem *menuItem = [statusMenu_ itemWithTag:kSIMenuUITagPrefix+[action uiTag]];
	FMTAssertNotNil(menuItem);
	
	[menuItem setTitle:[action label]];
	[menuItem setKeyEquivalent:[keyCodeString lowercaseString]];
	[menuItem setKeyEquivalentModifierMask:modifiers];
	[menuItem setRepresentedObject:[action identifier]];
	[menuItem setAction:@selector(shiftItMenuAction_:)];
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

- (void) shiftItActionHotKeyChanged_:(NSNotification *) notification {
	NSDictionary *userInfo = [notification userInfo];

	NSString *identifier = [userInfo objectForKey:kActionIdentifierKey];
	NSInteger keyCode = [[userInfo objectForKey:kHotKeyKeyCodeKey] integerValue];
	NSUInteger modifiers = [[userInfo objectForKey:kHotKeyModifiersKey] longValue];
	
	FMTDevLog(@"Updating action %@ hotKey: keyCode=%d modifiers=%ld", identifier, keyCode, modifiers);
	
	ShiftItAction *action = [allShiftActions objectForKey:identifier];
	FMTAssertNotNil(action);

	// register new hotkey
	FMTHotKey *newHotKey = [[FMTHotKey alloc] initWithKeyCode:keyCode modifiers:modifiers];
	FMTHotKey *hotKey = [allHotKeys_ objectForKey:identifier];
	if (hotKey) {
		if ([hotKey isEqualTo:newHotKey]) {
			FMTDevLog(@"Hot key is the same");
			return;
		}
		
		FMTDevLog(@"Unregistering old hot key: %@ for shiftIt action %@", hotKey, identifier);
		[hotKeyManager_ unregisterHotKey:hotKey];
	}
	
	FMTDevLog(@"Registering new hot key: %@ for shiftIt action %@", newHotKey, identifier);
	[hotKeyManager_ registerHotKey:newHotKey handler:@selector(invokeShiftItActionByIdentifier_:) provider:self userData:identifier];
	[allHotKeys_ setObject:newHotKey forKey:identifier];
	
	// update menu
	// TODO: disable if there is none
	[self updateStatusMenuShortcutForAction_:action keyCode:keyCode modifiers:modifiers];
	
	if ([notification object] != self) {
		// save to user preferences
		FMTDevLog(@"Updating user freferences with new hot key: %@ for shiftIt action %@", newHotKey, identifier);
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		[defaults setInteger:keyCode forKey:KeyCodePrefKey(identifier)];
		[defaults setInteger:modifiers forKey:ModifiersPrefKey(identifier)];
		[defaults synchronize];
	}
}

- (void) invokeShiftItActionByIdentifier_:(NSString *)identifier {
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