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

#import "PreferencesWindowController.h"
#import "ShiftItApp.h"

NSString *const kKeyCodePrefKeySuffix = @"KeyCode";
NSString *const kModifiersPrefKeySuffix = @"Modifiers";

NSString *const kDidFinishEditingHotKeysPrefNotification = @"kEnableActionsRequestNotification";
NSString *const kDidStartEditingHotKeysPrefNotification = @"kDisableActionsRequestNotification";
NSString *const kHotKeyChangedNotification = @"kHotKeyChangedNotification";
NSString *const kActionIdentifierKey = @"kActionIdentifierKey";
NSString *const kHotKeyKeyCodeKey = @"kHotKeyKeyCodeKey";
NSString *const kHotKeyModifiersKey = @"kHotKeyModifiersKey";

NSString *const kShiftItGithubIssueURL = @"https://github.com/fikovnik/ShiftIt/issues";

NSString *const kHotKeysTabViewItemIdentifier = @"hotKeys";

@interface PreferencesWindowController (Private)

- (void)windowMainStatusChanged_:(NSNotification *)notification;

@end


@implementation PreferencesWindowController

@dynamic shouldStartAtLogin;
@dynamic debugLogging;
@synthesize debugLoggingFile = debugLoggingFile_;

- (id)init {
    if (![super initWithWindowNibName:@"PreferencesWindow"]) {
        return nil;
    }

    return self;
}

- (BOOL)acceptsFirstResponder {
    return YES;
}

- (void)awakeFromNib {
    [tabView_ selectTabViewItemAtIndex:0];

    NSString *versionString = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
    [versionLabel_ setStringValue:versionString];

    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self selector:@selector(windowMainStatusChanged_:) name:NSWindowDidResignMainNotification object:[self window]];
    [notificationCenter addObserver:self selector:@selector(windowMainStatusChanged_:) name:NSWindowDidBecomeMainNotification object:[self window]];

    // no debug logging by default
    [self setDebugLoggingFile:@""];

    [self updateRecorderCombos];
}

- (IBAction)showPreferences:(id)sender {
    [[self window] center];
    [NSApp activateIgnoringOtherApps:YES];
    [[self window] makeKeyAndOrderFront:sender];
}

- (IBAction)revertDefaults:(id)sender {
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

-(IBAction)reportIssue:(id)sender {
    NSInteger ret = NSRunAlertPanel(NSLocalizedString(@"Before you report new issue", nil),
            NSLocalizedString(@"Please make sure that you look at the other issues before you submit a new one.", nil),
            NSLocalizedString(@"Take me to github.com", nil), NULL, NULL);
    
    if (ret == NSAlertDefaultReturn) {
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:kShiftItGithubIssueURL]];
    }
}

- (IBAction)revealLogFileInFinder:(id)sender {
    if (debugLoggingFile_) {
        NSURL *fileURL = [NSURL fileURLWithPath:debugLoggingFile_];
        [[NSWorkspace sharedWorkspace] selectFile:[fileURL path] inFileViewerRootedAtPath:nil];
    }
}

- (IBAction)showMenuBarIconAction:(id)sender {
    if (![showMenuIcon state]) {
        NSAlert *alert = [NSAlert
                alertWithMessageText:@"Disabling menu icon"
                       defaultButton:nil
                     alternateButton:nil
                         otherButton:nil
           informativeTextWithFormat:@"You chose to disable the menu icon. This means that you won't be able to easily open the Preferences window in the future.\n"
                   "\n"
                   "To open the Preferences window, while the menu icon is hidden, just relaunch the application."];
        
        [alert runModal];
    }
}


#pragma mark debugLogging dynamic property methods

- (BOOL)debugLogging {
    return !([[GTMLogger sharedLogger] writer] == [NSFileHandle fileHandleWithStandardOutput]);
}

- (void)setDebugLogging:(BOOL)flag {
    id <GTMLogWriter> writer = nil;

    if (flag) {
        NSString *logFile = FMTStr(@"%@/ShiftIt-debug-log-%@.txt",
                NSTemporaryDirectory(),
                [[NSDate date] stringWithFormat:@"YYYYMMDD-HHmm"]);

        FMTLogInfo(@"Enabling debug logging into file: %@", logFile);
        writer = [NSFileHandle fileHandleForLoggingAtPath:logFile mode:0644];
        [self setDebugLoggingFile:logFile];
    } else {
        FMTLogInfo(@"Enabling debug logging into stdout");
        writer = [NSFileHandle fileHandleWithStandardOutput];
        [self setDebugLoggingFile:@""];
    }

    [[GTMLogger sharedLogger] setWriter:writer];
}

#pragma mark shouldStartAtLogin dynamic property methods

- (BOOL)shouldStartAtLogin {
    NSString *path = [[NSBundle mainBundle] bundlePath];
    return [[FMTLoginItems sharedSessionLoginItems] isInLoginItemsApplicationWithPath:path];
}

- (void)setShouldStartAtLogin:(BOOL)flag {
    FMTLogDebug(@"ShiftIt should start at login: %d", flag);

    NSString *path = [[NSBundle mainBundle] bundlePath];
    [[FMTLoginItems sharedSessionLoginItems] toggleApplicationInLoginItemsWithPath:path enabled:flag];
}

#pragma mark Shortcut Recorder methods

static NSString *hotkeyIdentifiers[] = {
    @"left",
    @"right",
    @"top",
    @"bottom",
    NULL,
    @"tl",
    @"tr",
    @"bl",
    @"br",
    NULL,
    @"ltt",
    @"ltb",
    @"ctt",
    @"ctb",
    @"rtt",
    @"rtb",
    NULL,
    @"lt",
    @"ct",
    @"rt",
    NULL,
    @"center",
    @"zoom",
    @"maximize",
    @"fullScreen",
    NULL,
    @"increase",
    @"reduce",
    NULL,
    @"nextscreen",
    @"previousscreen"
};

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return sizeof(hotkeyIdentifiers) / sizeof(hotkeyIdentifiers[0]);
}

- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(NSInteger)rowIndex {
    return NO;
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
    FMTAssert(row >= 0 && row < sizeof(hotkeyIdentifiers) / sizeof(hotkeyIdentifiers[0]), @"Row out of range");
    NSString* identifier = hotkeyIdentifiers[row];
    if (identifier == NULL)
        return 1;
    return 23;
}

- (NSView *)tableView:(NSTableView *)tableView
   viewForTableColumn:(NSTableColumn *)tableColumn
                  row:(NSInteger)row {
    FMTAssert(row >= 0 && row < sizeof(hotkeyIdentifiers) / sizeof(hotkeyIdentifiers[0]), @"Row out of range");
    NSString* identifier = hotkeyIdentifiers[row];
    if (identifier == NULL)
        return NULL;
    ShiftItAction *action = [allShiftActions objectForKey:identifier];
    FMTAssertNotNil(action);
    if (tableColumn == hotkeyLabelColumn_) {
        NSTextField* text = [[NSTextField alloc] initWithFrame:tableView.frame];
        text.alignment = NSRightTextAlignment;
        text.drawsBackground = NO;
        text.stringValue = action.label;
        [text setBordered:NO];
        [text setEditable:NO];
        return text;
    }
    if (tableColumn == hotkeyColumn_) {
        SRRecorderControl* recorder = [[SRRecorderControl alloc] initWithFrame:tableView.frame];
        recorder.delegate = self;
        recorder.identifier = identifier;
        [self updateRecorderCombo:recorder forIdentifier:identifier];
        return recorder;
    }
    FMTFail(@"Unknown tableView or tableColumn");
    return NULL;
}

- (void)shortcutRecorder:(SRRecorderControl *)recorder keyComboDidChange:(KeyCombo)newKeyCombo {
    NSString *identifier = recorder.identifier;
    FMTAssertNotNil(identifier);

    ShiftItAction *action = [allShiftActions objectForKey:identifier];
    FMTAssertNotNil(action);

    FMTLogDebug(@"ShiftIt action %@ hotkey changed: ", [action identifier]);

    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithCapacity:3];
    [userInfo setObject:[action identifier] forKey:kActionIdentifierKey];
    [userInfo setObject:[NSNumber numberWithInteger:newKeyCombo.code] forKey:kHotKeyKeyCodeKey];
    [userInfo setObject:[NSNumber numberWithLong:newKeyCombo.flags] forKey:kHotKeyModifiersKey];

    [[NSNotificationCenter defaultCenter] postNotificationName:kHotKeyChangedNotification object:self userInfo:userInfo];
}

- (void)updateRecorderCombos {
    for (int row = 0; row < sizeof(hotkeyIdentifiers) / sizeof(hotkeyIdentifiers[0]); ++row) {
        NSString* identifier = hotkeyIdentifiers[row];
        if (identifier == NULL)
            continue;
        SRRecorderControl *recorder = [hotkeysView_ viewAtColumn:1 row:row makeIfNecessary:NO];
        if (recorder == NULL)
            continue;
        [self updateRecorderCombo:recorder forIdentifier:identifier];
    }
}

- (void)updateRecorderCombo:(SRRecorderControl *)recorder forIdentifier:(NSString *)identifier {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    KeyCombo combo;
    combo.code = [defaults integerForKey:KeyCodePrefKey(identifier)];
    combo.flags = [defaults integerForKey:ModifiersPrefKey(identifier)];
    [recorder setKeyCombo:combo];
}

#pragma mark TabView delegate methods

- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem {
    // TODO: why not to use the tabViewItem
    if ([selectedTabIdentifier_ isEqualTo:kHotKeysTabViewItemIdentifier]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kDidStartEditingHotKeysPrefNotification object:nil];
    } else {
        [[NSNotificationCenter defaultCenter] postNotificationName:kDidFinishEditingHotKeysPrefNotification object:nil];
    }
}

#pragma mark Notification handling methods

- (void)windowMainStatusChanged_:(NSNotification *)notification {
    NSString *name = [notification name];

    if ([name isEqualToString:NSWindowDidBecomeMainNotification] && [selectedTabIdentifier_ isEqualToString:kHotKeysTabViewItemIdentifier]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kDidStartEditingHotKeysPrefNotification object:nil];
    } else if ([name isEqualToString:NSWindowDidResignMainNotification]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kDidFinishEditingHotKeysPrefNotification object:nil];
    }
}

@end
