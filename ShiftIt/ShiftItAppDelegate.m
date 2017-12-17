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

#import <Sparkle/Sparkle.h>
#import "SBSystemPreferences.h"
#import "ShiftItAppDelegate.h"
#import "ShiftItApp.h"
#import "WindowGeometryShiftItAction.h"
#import "DefaultShiftItActions.h"
#import "PreferencesWindowController.h"
#import "AXWindowDriver.h"
#import "FMT/FMTNSFileManager+DirectoryLocations.h"

#ifdef X11
#import "X11WindowDriver.h"
#endif


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
NSString *const kMutipleActionsCycleWindowSizes = @"multipleActionsCycleWindowSizes";

// AX Driver Options
// TODO: should be moved to AX driver
NSString *const kAXIncludeDrawersPrefKey = @"axdriver_includeDrawers";
NSString *const kAXDriverConvergePrefKey = @"axdriver_converge";
NSString *const kAXDriverDelayBetweenOperationsPrefKey = @"axdriver_delayBetweenOperations";

// notifications
NSString *const kShowPreferencesRequestNotification = @"org.shiftitapp.shiftit.notifiactions.showPreferences";

// icon
NSString *const kSIIconName = @"ShiftItMenuIcon";
NSString *const kSIReversedIconName = @"ShiftItMenuIconReversed";

NSString *const kUsageStatisticsFileName = @"usage-statistics.plist";

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

@interface SIUsageStatistics : NSObject {
@private
    NSMutableDictionary *statistics_;

}

- (id)initFromFile:(NSString *)path;

- (void)increment:(NSString *)key;

- (void)saveToFile:(NSString *)path;

- (NSArray *)toSparkle;

@end

@implementation SIUsageStatistics

- (id)initFromFile:(NSString *)path {
    if (![super init]) {
        return nil;
    }

    NSFileManager *fm = [NSFileManager defaultManager];

    if (![fm fileExistsAtPath:path]) {
        FMTLogInfo(@"Usage statistics do not exists");
        statistics_ = [[NSMutableDictionary dictionary] retain];
    } else {
        NSData *data = nil;
        NSString *errorDesc = nil;
        NSPropertyListFormat format = NSPropertyListBinaryFormat_v1_0;

        data = [fm contentsAtPath:path];
        NSDictionary *d = (NSDictionary *) [NSPropertyListSerialization
                propertyListFromData:data
                    mutabilityOption:NSPropertyListMutableContainersAndLeaves
                              format:&format
                    errorDescription:&errorDesc];

        if (d) {
            FMTLogInfo(@"Loaded usage statistics from: %@", path);
            statistics_ = [[NSMutableDictionary dictionaryWithDictionary:d] retain];
        } else {
            FMTLogError(@"Error reading usage statistics: %@ from: %@ format: %ld", errorDesc, path, NSPropertyListBinaryFormat_v1_0);
            statistics_ = [[NSMutableDictionary dictionary] retain];
        }
    }

    return self;
}

- (void)dealloc {
    [statistics_ release];

    [super dealloc];
}

- (void)increment:(NSString *)key {
    NSInteger value = 0;

    id stat = [statistics_ objectForKey:key];
    if (stat) {
        value = [(NSNumber *) stat integerValue];
    }

    stat = [NSNumber numberWithInteger:(value + 1)];
    [statistics_ setObject:stat forKey:key];
}

- (void)saveToFile:(NSString *)path {
    NSData *data = nil;
    NSString *errorDesc = nil;

    data = [NSPropertyListSerialization dataFromPropertyList:statistics_
                                                      format:NSPropertyListBinaryFormat_v1_0
                                            errorDescription:&errorDesc];

    if (data) {
        [data writeToFile:path atomically:YES];
        FMTLogInfo(@"Save usage statitics to: %@", path);
    } else {
        FMTLogError(@"Unable to serialize usage statistics to: %@ - %@", path, errorDesc);
    }
}


- (NSArray *)toSparkle {
    NSMutableArray *a = [NSMutableArray array];

    [statistics_ enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
        [a addObject:FMTEncodeForSparkle(key, value, key, value)];
    }];

    return [NSArray arrayWithArray:a];
}
@end

@implementation ShiftItAction

@synthesize identifier = identifier_;
@synthesize label = label_;
@synthesize uiTag = uiTag_;
@synthesize delegate = delegate_;

- (id)initWithIdentifier:(NSString *)identifier label:(NSString *)label uiTag:(NSInteger)uiTag delegate:(id <SIActionDelegate>)delegate {
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

- (BOOL)execute:(id <SIWindowContext>)windowContext error:(NSError **)error {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:FMTStr(@"You must override %@ in a subclass", NSStringFromSelector(_cmd))
                                 userInfo:nil];
}

@end

@interface ShiftItAppDelegate ()

- (void)checkAuthorization;

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

@implementation ShiftItAppDelegate {
@private
    PreferencesWindowController *preferencesController_;
    FMTHotKeyManager *hotKeyManager_;
    SIWindowManager *windowManager_;

    SIUsageStatistics *usageStatistics_;
    NSMutableDictionary *allHotKeys_;
    BOOL paused_;

    NSStatusItem *statusItem_;

    // to keep some pause between action invocations
    CFAbsoluteTime beforeNow_;
}

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

    allHotKeys_ = [[NSMutableDictionary alloc] init];
    NSString *usageStatisticsFile = [[[NSFileManager defaultManager] applicationSupportDirectory] stringByAppendingPathComponent:kUsageStatisticsFileName];
    usageStatistics_ = [[SIUsageStatistics alloc] initFromFile:usageStatisticsFile];

    beforeNow_ = CFAbsoluteTimeGetCurrent();

    return self;
}

- (void)dealloc {
    [allShiftActions release];
    [windowManager_ release];
    [allHotKeys_ release];
    [preferencesController_ release];
    [usageStatistics_ release];

    [super dealloc];
}

- (void)firstLaunch_ {
    FMTLogInfo(@"First run");
    // ask to start it automatically - make sure it is not there

    // TODO: refactor this so it shares the code from the pref controller
    FMTLoginItems *loginItems = [FMTLoginItems sharedSessionLoginItems];
    NSString *appPath = [[NSBundle mainBundle] bundlePath];

    if (![loginItems isInLoginItemsApplicationWithPath:appPath]) {
        NSInteger ret = NSRunAlertPanel(NSLocalizedString(@"Start ShiftIt automatically?", nil),
                                        NSLocalizedString(@"Would you like to have ShiftIt automatically started at a login time?", nil),
                                        NSLocalizedString(@"Yes", nil), NSLocalizedString(@"No", nil), NULL);
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

- (void)checkAuthorization {
    // TODO: move to driver
    if (!AXIsProcessTrusted()) {
        FMTLogInfo(@"ShiftIt not is authorized");

        if (AXIsProcessTrustedWithOptions != NULL) {
            // OSX >= 10.9

            NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Authorization Required", nil)
                                             defaultButton:NSLocalizedString(@"Recheck", nil)
                                           alternateButton:NSLocalizedString(@"Open System Preferences", nil)
                                               otherButton:NSLocalizedString(@"Quit", nil)
                                 informativeTextWithFormat:NSLocalizedString(@"AUTHORIZATION_INFORMATIVE_TEXT_10_9", nil)
            ];

            NSImageView *accessory = [[[NSImageView alloc] initWithFrame:NSMakeRect(0, 0, 300, 234)] autorelease];
            [accessory setImage:[NSImage imageNamed:@"AccessibilitySettingsMaverick"]];
            [accessory setImageFrameStyle:NSImageFrameGrayBezel];
            [alert setAccessoryView:accessory];

            BOOL recheck = true;
            while (recheck) {
                switch ([alert runModal]) {
                    case NSAlertDefaultReturn:
                        recheck = !AXIsProcessTrusted();
                        break;
                    case NSAlertOtherReturn:
                        [NSApp terminate:self];
                        break;
                    case NSAlertAlternateReturn: {

                        // this should hopefully add it to the list so user can only click on the checkbox
                        NSDictionary *options = @{(id) kAXTrustedCheckOptionPrompt : @NO};
                        AXIsProcessTrustedWithOptions((CFDictionaryRef) options);

                        SBSystemPreferencesApplication *prefs = [SBApplication applicationWithBundleIdentifier:@"com.apple.systempreferences"];
                        [prefs activate];

                        SBSystemPreferencesPane *pane = [[prefs panes] find:^BOOL(SBSystemPreferencesPane *elem) {
                            return [[elem id] isEqualToString:@"com.apple.preference.security"];
                        }];
                        SBSystemPreferencesAnchor *anchor = [[pane anchors] find:^BOOL(SBSystemPreferencesAnchor *elem) {
                            return [[elem name] isEqualToString:@"Privacy_Accessibility"];
                        }];

                        [anchor reveal];
                    }
                        break;
                    default:
                        break;
                }

            }
        } else {
            // OSX <= 10.8
            NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Authorization Required", nil)
                                             defaultButton:NSLocalizedString(@"Quit", nil)
                                           alternateButton:nil
                                               otherButton:NSLocalizedString(@"Open System Preferences", nil)
                                 informativeTextWithFormat:NSLocalizedString(@"AUTHORIZATION_INFORMATIVE_TEXT_10_8", nil)
            ];

            NSImageView *accessory = [[[NSImageView alloc] initWithFrame:NSMakeRect(0, 0, 300, 234)] autorelease];
            [accessory setImage:[NSImage imageNamed:@"AccessibilitySettingsLion"]];
            [accessory setImageFrameStyle:NSImageFrameGrayBezel];
            [alert setAccessoryView:accessory];

            if ([alert runModal] == NSAlertOtherReturn) {
                [[NSWorkspace sharedWorkspace] openFile:@"/System/Library/PreferencePanes/UniversalAccessPref.prefPane"];
            }

            [NSApp terminate:self];
        }
    }
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    FMTLogDebug(@"Starting up ShiftIt...");

    [self checkAuthorization];

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    // check preferences
    BOOL hasStartedBefore = [defaults boolForKey:kHasStartedBeforePrefKey];

    if (!hasStartedBefore) {
        // make sure this was the only time
        [defaults setBool:YES forKey:@"hasStartedBefore"];
        [defaults synchronize];

        [self firstLaunch_];
    }

    hotKeyManager_ = [FMTHotKeyManager sharedHotKeyManager];

    NSMutableArray *drivers = [NSMutableArray array];
    NSError *error = nil;

    // initialize AX driver
    // TODO: keep the reference and register listener for preference changes
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
        FMTLogInfo(@"Unable to load AX driver: %@%@", [error localizedDescription], [error fullDescription]);
    } else {
        FMTLogInfo(@"Added driver: %@", [axDriver description]);
        [drivers addObject:axDriver];
    }

#ifdef X11
    // initialize X11 driver
    X11WindowDriver *x11Driver = [[[X11WindowDriver alloc] initWithError:&error] autorelease];
    if (error) {
        FMTLogInfo(@"Unable to load X11 driver: %@%@", [error localizedDescription], [error fullDescription]);
    } else {
        FMTLogInfo(@"Added driver: %@", [x11Driver description]);
        [drivers addObject:x11Driver];
    }

    if ([drivers count] == 0) {
        FMTLogError(@"No driver could be loaded - exiting");
        // TODO: externalize
        [NSApp presentError:SICreateError(100, @"No driver could be loaded")];
        [NSApp terminate:self];
    }
#endif

    windowManager_ = [[SIWindowManager alloc] initWithDrivers:[NSArray arrayWithArray:drivers]];

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

    // save usage statistics
    NSString *usageStatisticsFile = [[[NSFileManager defaultManager] applicationSupportDirectory] stringByAppendingPathComponent:kUsageStatisticsFileName];
    [usageStatistics_ saveToFile:usageStatisticsFile];

    // unregister hotkeys
    for (FMTHotKey *hotKey in [allHotKeys_ allValues]) {
        [hotKeyManager_ unregisterHotKey:hotKey];
    }
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)flag {
    if (flag == NO) {
        [self showPreferences:nil];
    }
    return NO;
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
            NSImage *icon = [NSImage imageNamed:kSIIconName];
            [icon setTemplate:YES];
            
            statusItem_ = [[statusBar statusItemWithLength:kSIMenuItemSize] retain];
            [statusItem_ setMenu:statusMenu_];
            [statusItem_ setImage:icon];
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
    action = [[[ShiftItAction alloc] initWithIdentifier:(anId) label:(aLabel) uiTag:(aTag) delegate:(aDelegate)] autorelease]; \
    [(dict) setObject:action forKey:[action identifier]];

    REGISTER_ACTION(dict, @"left", NSLocalizedString(@"Left", nil), 1, [[[WindowGeometryShiftItAction alloc] initWithBlock:shiftItLeft] autorelease]);
    REGISTER_ACTION(dict, @"right", NSLocalizedString(@"Right", nil), 2, [[[WindowGeometryShiftItAction alloc] initWithBlock:shiftItRight] autorelease]);
    REGISTER_ACTION(dict, @"top", NSLocalizedString(@"Top", nil), 3, [[[WindowGeometryShiftItAction alloc] initWithBlock:shiftItTop] autorelease]);
    REGISTER_ACTION(dict, @"bottom", NSLocalizedString(@"Bottom", nil), 4, [[[WindowGeometryShiftItAction alloc] initWithBlock:shiftItBottom] autorelease]);
    REGISTER_ACTION(dict, @"tl", NSLocalizedString(@"Top Left", nil), 5, [[[WindowGeometryShiftItAction alloc] initWithBlock:shiftItTopLeft] autorelease]);
    REGISTER_ACTION(dict, @"tr", NSLocalizedString(@"Top Right", nil), 6, [[[WindowGeometryShiftItAction alloc] initWithBlock:shiftItTopRight] autorelease]);
    REGISTER_ACTION(dict, @"bl", NSLocalizedString(@"Bottom Left", nil), 7, [[[WindowGeometryShiftItAction alloc] initWithBlock:shiftItBottomLeft] autorelease]);
    REGISTER_ACTION(dict, @"br", NSLocalizedString(@"Bottom Right", nil), 8, [[[WindowGeometryShiftItAction alloc] initWithBlock:shiftItBottomRight] autorelease]);
    REGISTER_ACTION(dict, @"center", NSLocalizedString(@"Center", nil), 9, [[[WindowGeometryShiftItAction alloc] initWithBlock:shiftItCenter] autorelease]);
    REGISTER_ACTION(dict, @"zoom", NSLocalizedString(@"Toggle Zoom", nil), 10, [[[ToggleZoomShiftItAction alloc] init] autorelease]);
    REGISTER_ACTION(dict, @"maximize", NSLocalizedString(@"Maximize", nil), 11, [[[WindowGeometryShiftItAction alloc] initWithBlock:shiftItFullScreen] autorelease]);
    REGISTER_ACTION(dict, @"fullScreen", NSLocalizedString(@"Toggle Full Screen", nil), 12, [[[ToggleFullScreenShiftItAction alloc] init] autorelease]);
    REGISTER_ACTION(dict, @"increase", NSLocalizedString(@"Increase", nil), 13, [[[IncreaseReduceShiftItAction alloc] initWithMode:YES] autorelease]);
    REGISTER_ACTION(dict, @"reduce", NSLocalizedString(@"Reduce", nil), 14, [[[IncreaseReduceShiftItAction alloc] initWithMode:NO] autorelease]);
    REGISTER_ACTION(dict, @"nextscreen", NSLocalizedString(@"Next Screen", nil), 15, [[[ScreenChangeShiftItAction alloc] initWithMode:YES] autorelease]);
    REGISTER_ACTION(dict, @"previousscreen", NSLocalizedString(@"Previous Screen", nil), 16, [[[ScreenChangeShiftItAction alloc] initWithMode:NO] autorelease]);

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
            FMTLogError(@"Execution of ShiftIt action: %@ failed: %@%@", [action identifier],
                            [error localizedDescription],
                            [error fullDescription]);
        }
        [usageStatistics_ increment:FMTStr(@"action_%@", identifier)];
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

// This method allows you to add extra parameters to the appcast URL,
// potentially based on whether or not Sparkle will also be sending along
// the system profile. This method should return an array of dictionaries
// with keys: "key", "value", "displayKey", "displayValue", the latter two
// being human-readable variants of the former two.
- (NSArray *)feedParametersForUpdater:(SUUpdater *)updater
                 sendingSystemProfile:(BOOL)sendingProfile {
    NSMutableArray *a = [NSMutableArray arrayWithArray:[usageStatistics_ toSparkle]];

    // get display information
    NSArray *screens = [NSScreen screens];
    NSInteger nScreen = [screens count];
    [a addObject:FMTEncodeForSparkle(@"n_screens", FMTStr(@"%d", nScreen), @"Number of screens", FMTStr(@"%d", nScreen))];

    for (NSUInteger i = 0; i < nScreen; i++) {
        NSString *resolution = RECT_STR([[screens objectAtIndex:i] frame]);
        [a addObject:FMTEncodeForSparkle(FMTStr(@"screen_%d", i), resolution, FMTStr(@"Screen #%d resolution", i), resolution)];
    }

    return [NSArray arrayWithArray:a];
}


@end
