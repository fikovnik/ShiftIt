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
#import "ShiftItApp.h"
#import "WindowGeometryShiftItAction.h"
#import "DefaultShiftItActions.h"
#import "PreferencesWindowController.h"
#import "ShiftItWindowManager.h"
#import "AXWindowDriver.h"
#import "X11WindowDriver.h"
#import "FMTLoginItems.h"
#import "FMTHotKey.h"
#import "FMTHotKeyManager.h"
#import "FMTUtils.h"
#import "FMTNSError+Extras.h"
#import "FMTDefines.h"

NSString *const kShiftItAppBundleId = @"org.shiftitapp.ShiftIt";

// the name of the plist file containing the preference defaults
NSString *const kShiftItUserDefaults = @"ShiftIt-defaults";

// preferences
NSString *const kHasStartedBeforePrefKey = @"hasStartedBefore";
NSString *const kShowMenuPrefKey = @"shiftItshowMenu";
NSString *const kMarginsEnabledPrefKey = @"marginsEnabled";
NSString *const kLeftMarginPrefKey = @"leftMargin";
NSString *const kTopMarginPrefKey = @"topMargin";
NSString *const kBottomMarginPrefKey = @"bottomMargin";
NSString *const kRightMarginPrefKey = @"rightMargin";
NSString *const kSizeDeltaTypePrefKey = @"sizeDeltaType";
NSString *const kFixedSizeWidthDeltaPrefKey = @"fixedSizeWidthDelta";
NSString *const kFixedSizeHeightDeltaPrefKey = @"fixedSizeHeightDelta";
NSString *const kWindowSizeDeltaPrefKey = @"windowSizeDelta";
NSString *const kScreenSizeDeltaPrefKey = @"screenSizeDelta";
// AX Driver Options
NSString *const kAXIncludeDrawersPrefKey = @"axdriver_includeDrawers";
NSString *const kAXDriverConvergePrefKey = @"axdriver_converge";
NSString *const kAXDriverDelayBetweenOperationsPrefKey = @"axdriver_delayBetweenOperations";

// notifications
NSString *const kShowPreferencesRequestNotification = @"org.shiftitapp.shiftit.notifiactions.showPreferences";

// icon
NSString *const kSIIconName = @"ShiftIt-menuIcon";
NSString *const kSIMenuItemTitle = @"Shift";

// the size that should be reserved for the menu item in the system menu in px
NSInteger const kSIMenuItemSize = 30;

NSInteger const kSIMenuUITagPrefix = 2000;

// even if the user settings is higher - this defines the absolute max of tries
NSInteger const kMaxNumberOfTries = 20;

// error related
NSString *const SIAErrorDomain = @"org.shiftitapp.app.error";

const CFAbsoluteTime kMinimumTimeBetweenActionInvocations = 0.25; // in seconds

// TODO: move to the class
NSDictionary *allShiftActions = nil;

@implementation ShiftItAction

@synthesize identifier = identifier_;
@synthesize label = label_;
@synthesize uiTag = uiTag_;
@synthesize delegate = delegate_;

- (id)initWithIdentifier:(NSString *)identifier label:(NSString *)label uiTag:(NSInteger)uiTag delegate:(id <ShiftItActionDelegate>)delegate {
    FMTAssertNotNil(identifier);
    FMTAssertNotNil(label);
    FMTAssert(uiTag > 0, @"uiTag must be greater than 0");
    FMTAssertNotNil(delegate);

    if (![super init]) {
        return nil;
    }

    identifier_ = [identifier retain];
    label_ = [label retain];
    uiTag_ = uiTag;
    delegate_ = [delegate retain];

    return self;
}

- (void)dealloc {
    [identifier_ release];
    [label_ release];
    [delegate_ release];

    [super dealloc];
}

- (BOOL)execute:(id <WindowContext>)windowContext error:(NSError **)error {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:FMTStr(@"You must override %@ in a subclass", NSStringFromSelector(_cmd))
                                 userInfo:nil];
}

@end


@interface ShiftItAppDelegate (Private)

- (void)initializeActions_;

- (void)updateMenuBarIcon_;

- (void)firstLaunch_;

- (void)invokeShiftItActionByIdentifier_:(NSString *)identifier;

- (void)updateStatusMenuShortcutForAction_:(ShiftItAction *)action keyCode:(NSInteger)keyCode modifiers:(NSUInteger)modifiers;

- (void)handleShowPreferencesRequest_:(NSNotification *)notification;

- (void)shiftItActionHotKeyChanged_:(NSNotification *)notification;

- (void)handleActionsStateChangeRequest_:(NSNotification *)notification;

- (IBAction)shiftItMenuAction_:(id)sender;

@end


@implementation ShiftItAppDelegate

+ (void)initialize {
    // register defaults - we assume that the installation is correct
    NSString *path = FMTGetMainBundleResourcePath(kShiftItUserDefaults, @"plist");
    NSDictionary *d = [NSDictionary dictionaryWithContentsOfFile:path];

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults registerDefaults:d];
}

- (id)init {
    if (![super init]) {
        return nil;
    }

    NSString *iconPath = FMTGetMainBundleResourcePath(kSIIconName, @"png");
    statusMenuItemIcon_ = [[NSImage alloc] initWithContentsOfFile:iconPath];
    allHotKeys_ = [[NSMutableDictionary alloc] init];

    beforeNow_ = CFAbsoluteTimeGetCurrent();

    return self;
}

- (void)dealloc {
    [statusMenuItemIcon_ release];
    [allShiftActions release];
    [windowManager_ release];


    [super dealloc];
}

- (void)firstLaunch_ {
    FMTLogInfo(@"First run");
    // ask to start it automatically - make sure it is not there

    // TODO: refactor this so it shares the code from the pref controller
    FMTLoginItems *loginItems = [FMTLoginItems sharedSessionLoginItems];
    NSString *appPath = [[NSBundle mainBundle] bundlePath];

    if (![loginItems isInLoginItemsApplicationWithPath:appPath]) {
        int ret = NSRunAlertPanel(@"Start ShiftIt automatically?", @"Would you like to have ShiftIt automatically started at a login time?", @"Yes", @"No", NULL);
        switch (ret) {
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

    if (!AXAPIEnabled()) {
        int ret = NSRunAlertPanel(@"UI Element Inspector requires that the Accessibility API be enabled.  Please \"Enable access for assistive devices and try again\".", @"", @"OK", @"Cancel", NULL);
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

    NSMutableArray *drivers = [NSMutableArray array];
    NSError *error = nil;

    // initialize AX driver
    AXWindowDriver *axDriver = [[[AXWindowDriver alloc] initWithError:&error] autorelease];
    // set defaults
    if ([defaults objectForKey:kAXIncludeDrawersPrefKey]) {
        [axDriver setShouldUseDrawers:[defaults boolForKey:kAXIncludeDrawersPrefKey]];
    }
    if ([defaults objectForKey:kAXDriverConvergePrefKey]) {
        [axDriver setConverge:[defaults boolForKey:kAXDriverConvergePrefKey]];
    }
    if ([defaults objectForKey:kAXDriverDelayBetweenOperationsPrefKey]) {
        [axDriver setDelayBetweenOperations:[defaults doubleForKey:kAXDriverDelayBetweenOperationsPrefKey]];
    }

    if (error) {
        FMTLogDebug(@"Unable to load AX driver: %@%@", [error localizedDescription], [error fullDescription]);
    } else {
        FMTLogDebug(@"Added driver: %@", [axDriver description]);
       [drivers addObject:axDriver];
    }

    // initialize X11 driver
    X11WindowDriver *x11Driver = [[[X11WindowDriver alloc] initWithError:&error] autorelease];
    if (error) {
        FMTLogDebug(@"Unable to load X11 driver: %@%@", [error localizedDescription], [error fullDescription]);
    } else {
        FMTLogDebug(@"Added driver: %@", [x11Driver description]);
       [drivers addObject:x11Driver];
    }

    if ([drivers count] == 0) {
        FMTLogError(@"No driver could be loaded - exiting");
        // TODO: externalize
        [NSApp presentError:SICreateError(100, @"No driver could be loaded")];
        [NSApp terminate:self];
    }

	windowManager_ = [[ShiftItWindowManager alloc] initWithDrivers:[NSArray arrayWithArray:drivers]];

    [self initializeActions_];
    [self updateMenuBarIcon_];

    NSUserDefaultsController *userDefaultsController = [NSUserDefaultsController sharedUserDefaultsController];
    [userDefaultsController addObserver:self forKeyPath:FMTStr(@"values.%@", kShowMenuPrefKey) options:0 context:self];

    for (ShiftItAction *action in [allShiftActions allValues]) {
        NSString *identifier = [action identifier];

        NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithCapacity:3];
        [userInfo setObject:[action identifier] forKey:kActionIdentifierKey];
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

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    FMTLogInfo(@"Shutting down ShiftIt...");

    // unregister hotkeys
    for (FMTHotKey *hotKey in [allHotKeys_ allValues]) {
        [hotKeyManager_ unregisterHotKey:hotKey];
    }
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)flag {
    if (flag == NO) {
        [self showPreferences:nil];
    }
    return YES;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([FMTStr(@"values.%@", kShowMenuPrefKey) isEqualToString:keyPath]) {
        [self updateMenuBarIcon_];
    }
}

- (void)updateMenuBarIcon_ {
    BOOL showIconInMenuBar = [[NSUserDefaults standardUserDefaults] boolForKey:kShowMenuPrefKey];
    NSStatusBar *statusBar = [NSStatusBar systemStatusBar];

    if (showIconInMenuBar) {
        if (!statusItem_) {
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
        preferencesController_ = [[PreferencesWindowController alloc] init];
    }

    [preferencesController_ showPreferences:sender];
    [NSApp activateIgnoringOtherApps:YES];
}

- (void)updateStatusMenuShortcutForAction_:(ShiftItAction *)action keyCode:(NSInteger)keyCode modifiers:(NSUInteger)modifiers {
    FMTAssertNotNil(action);
    FMTLogDebug(@"updateStatusMenuShortcutForAction_:%@ keyCode:%ld modifiers:%ld", [action identifier], keyCode, modifiers);

    NSMenuItem *menuItem = [statusMenu_ itemWithTag:kSIMenuUITagPrefix + [action uiTag]];
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

- (void)initializeActions_ {
    FMTAssert(allShiftActions == nil, @"Actions have been already initialized");

    NSMutableDictionary *dict = [NSMutableDictionary dictionary];

    // TODO: this is ugly but just temp
    ShiftItAction *action = nil;

#define REGISTER_ACTION(dict, anId, aLabel, aTag, aDelegate) \
    action = [[ShiftItAction alloc] initWithIdentifier:(anId) label:(aLabel) uiTag:(aTag) delegate:(aDelegate)]; \
    [(dict) setObject:action forKey:[action identifier]];

    REGISTER_ACTION(dict, @"left", @"Left", 1, [[[WindowGeometryShiftItAction alloc] initWithBlock:shiftItLeft] autorelease]);
    REGISTER_ACTION(dict, @"right", @"Right", 2, [[[WindowGeometryShiftItAction alloc] initWithBlock:shiftItRight] autorelease]);
    REGISTER_ACTION(dict, @"top", @"Top", 3, [[[WindowGeometryShiftItAction alloc] initWithBlock:shiftItTop] autorelease]);
    REGISTER_ACTION(dict, @"bottom", @"Bottom", 4, [[[WindowGeometryShiftItAction alloc] initWithBlock:shiftItBottom] autorelease]);
    REGISTER_ACTION(dict, @"tl", @"Top Left", 5, [[[WindowGeometryShiftItAction alloc] initWithBlock:shiftItTopLeft] autorelease]);
    REGISTER_ACTION(dict, @"tr", @"Top Right", 6, [[[WindowGeometryShiftItAction alloc] initWithBlock:shiftItTopRight] autorelease]);
    REGISTER_ACTION(dict, @"bl", @"Bottom Left", 7, [[[WindowGeometryShiftItAction alloc] initWithBlock:shiftItBottomLeft] autorelease]);
    REGISTER_ACTION(dict, @"br", @"Bottom Right", 8, [[[WindowGeometryShiftItAction alloc] initWithBlock:shiftItBottomRight] autorelease]);
    REGISTER_ACTION(dict, @"center", @"Center", 9, [[[WindowGeometryShiftItAction alloc] initWithBlock:shiftItCenter] autorelease]);
    REGISTER_ACTION(dict, @"zoom", @"Toggle Zoom", 10, [[[ToggleZoomShiftItAction alloc] init] autorelease]);
    REGISTER_ACTION(dict, @"maximize", @"Maximize", 11, [[[WindowGeometryShiftItAction alloc] initWithBlock:shiftItFullScreen] autorelease]);
    REGISTER_ACTION(dict, @"fullScreen", @"Toggle Full Screen", 12, [[[ToggleFullScreenShiftItAction alloc] init] autorelease]);
    REGISTER_ACTION(dict, @"increase", @"Increase", 13, [[[IncreaseReduceShiftItAction alloc] initWithMode:YES] autorelease]);
    REGISTER_ACTION(dict, @"reduce", @"Reduce", 14, [[[IncreaseReduceShiftItAction alloc] initWithMode:NO] autorelease]);


#undef REGISTER_ACTION

    allShiftActions = [[NSDictionary dictionaryWithDictionary:dict] retain];
}

- (void)handleShowPreferencesRequest_:(NSNotification *)notification {
    [self showPreferences:self];
}

- (void)handleActionsStateChangeRequest_:(NSNotification *)notification {
    NSString *name = [notification name];

    if ([name isEqualToString:kDidFinishEditingHotKeysPrefNotification]) {
        @synchronized (self) {
            paused_ = NO;
            FMTLogDebug(@"Resuming actions");
        }
    } else if ([name isEqualToString:kDidStartEditingHotKeysPrefNotification]) {
        @synchronized (self) {
            paused_ = YES;
            FMTLogDebug(@"Pausing actions");
        }
    }

}

- (void)shiftItActionHotKeyChanged_:(NSNotification *)notification {
    NSDictionary *userInfo = [notification userInfo];

    NSString *identifier = [userInfo objectForKey:kActionIdentifierKey];
    NSInteger keyCode = [[userInfo objectForKey:kHotKeyKeyCodeKey] integerValue];
    NSUInteger modifiers = [[userInfo objectForKey:kHotKeyModifiersKey] longValue];

    FMTLogDebug(@"Updating action %@ hotKey: keyCode=%ld modifiers=%ld", identifier, keyCode, modifiers);

    ShiftItAction *action = [allShiftActions objectForKey:identifier];
    FMTAssertNotNil(action);

    FMTHotKey *newHotKey = [[[FMTHotKey alloc] initWithKeyCode:keyCode modifiers:modifiers] autorelease];

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

- (void)invokeShiftItActionByIdentifier_:(NSString *)identifier {
    // TODO: use grand central dispatch instead synchronize!
    @synchronized (self) {
        if (paused_) {
            FMTLogDebug(@"The functionality is temporarly paused");
            return;
        }

        CFAbsoluteTime now = CFAbsoluteTimeGetCurrent();

        // since now can be actually smaller than beforeNow_ due to sync
        // we just drop it anyway and hope next time we have more luck
        if (now > beforeNow_ && now - beforeNow_ < kMinimumTimeBetweenActionInvocations) {
            // drop it - too soon new request
            // we need to give the AXUI and others some time to recover :)
            // otherwise some weird results are experienced
            FMTLogDebug(@"Action executed too soon after the last one: %f (minimum: %f)",
            now - beforeNow_,
            kMinimumTimeBetweenActionInvocations);
            return;
        } else {
            beforeNow_ = now;
        }

        ShiftItAction *action = [allShiftActions objectForKey:identifier];
        FMTAssertNotNil(action);

        FMTLogInfo(@"Invoking action: %@", identifier);
        NSError *error = nil;
        if (![windowManager_ executeAction:[action delegate] error:&error]) {
            FMTLogError(@"Execution of ShiftIt action: %@ failed: %@%@", [action identifier], [error localizedDescription], [error fullDescription]);
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