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
#import "FMTLoginItems.h"
#import "FMTDefines.h"
#import "FMTUtils.h"
#import "FMTNSDictionary+Extras.h"
#import "FMTNSDate+Extras.h"
#import "GTMLogger.h"

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

@interface PreferencesWindowController(Private) 

- (void)windowMainStatusChanged_:(NSNotification *)notification;

@end


@implementation PreferencesWindowController

@dynamic shouldStartAtLogin;
@dynamic debugLogging;
@synthesize debugLoggingFile = debugLoggingFile_;

-(id)init{
    if (![super initWithWindowNibName:@"PreferencesWindow"]) {
		return nil;
    }
    
    return self;
}

-(void)dealloc{
    [hotKeyControls_ release];
    
	[super dealloc];
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
	
    // no debug logging by default
    [self setDebugLoggingFile:@""];
    
    // This is just temporary here - till new version
    NSArray *controls = [NSArray arrayWithObjects:srLeft_, 
                         srBottom_,
                         srTop_, 
                         srRight_, 
                         srTL_, 
                         srTR_, 
                         srBR_, 
                         srBL_, 
                         srCenter_, 
                         srZoom_, 
                         srMaximize_, 
                         srFullScreen_, 
                         srIncrease_,
                         srReduce_,
                         srNextScreen_,
                         nil];
    NSArray *keys = [NSArray arrayWithObjects:@"left", 
                     @"bottom",
                     @"top", 
                     @"right",
                     @"tl", 
                     @"tr",
                     @"br", 
                     @"bl",
                     @"center",
                     @"zoom",
                     @"maximize",
                     @"fullScreen",
                     @"increase",
                     @"reduce", 
                     @"nextscreen", 
                     nil];
    
    hotKeyControls_ = [[NSDictionary dictionaryWithObjects:controls forKeys:keys] retain];
    
	[self updateRecorderCombos];
}

-(IBAction)showPreferences:(id)sender {
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

-(IBAction)reportIssue:(id)sender {
    NSInteger ret = NSRunAlertPanel(NSLocalizedString(@"Before you report new issue", nil),
            NSLocalizedString(@"Please make sure that you look at the other issues before you submit a new one.", nil),
            NSLocalizedString(@"Take me to github.com", nil), NULL, NULL);
    
    if (ret == NSAlertDefaultReturn) {
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:kShiftItGithubIssueURL]];
    }
}

-(IBAction)revealLogFileInFinder:(id)sender {
    if (debugLoggingFile_) {
        NSURL *fileURL = [NSURL fileURLWithPath:debugLoggingFile_];
        [[NSWorkspace sharedWorkspace] selectFile:[fileURL path] inFileViewerRootedAtPath:nil];
    }
}


#pragma mark debugLogging dynamic property methods

- (BOOL) debugLogging {
    return !([[GTMLogger sharedLogger] writer] == [NSFileHandle fileHandleWithStandardOutput]);
}

- (void)setDebugLogging:(BOOL)flag {
    id<GTMLogWriter> writer = nil; 

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

- (void)shortcutRecorder:(SRRecorderControl *)recorder keyComboDidChange:(KeyCombo)newKeyCombo{
    NSString *identifier = [hotKeyControls_ keyForObject:recorder];
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
	NSInteger idx = [tabView_ indexOfTabViewItemWithIdentifier:@"hotKeys"];
	NSView *hotKeysView = [[tabView_ tabViewItemAtIndex:idx] view];
	FMTAssertNotNil(hotKeysView);
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
	for (ShiftItAction *action in [allShiftActions allValues]) {
		NSString *identifier = [action identifier];
		SRRecorderControl *recorder = [hotKeyControls_ objectForKey:identifier];
		FMTAssertNotNil(recorder);
        
		
		KeyCombo combo;
		combo.code = [defaults integerForKey:KeyCodePrefKey(identifier)];
		combo.flags = [defaults integerForKey:ModifiersPrefKey(identifier)];
		[recorder setKeyCombo:combo];		
	}	
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
