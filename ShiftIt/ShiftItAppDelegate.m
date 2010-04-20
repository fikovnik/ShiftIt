//
//  ShiftItAppDelegate.m
//  ShiftIt
//
//  Created by Aravindkumar Rajendiran on 10-02-13.
//  Copyright 2010 Grapewave. All rights reserved.
//

#import "ShiftItAppDelegate.h"

@implementation ShiftItAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	if (!AXAPIEnabled()){
        int ret = NSRunAlertPanel (@"UI Element Inspector requires that the Accessibility API be enabled.  Please \"Enable access for assistive devices and try again\".", @"", @"OK", @"Cancel",NULL);
        switch (ret){
            case NSAlertDefaultReturn:
                [[NSWorkspace sharedWorkspace] openFile:@"/System/Library/PreferencePanes/UniversalAccessPref.prefPane"];
				[NSApp terminate:self];
				return;
                break;
            case NSAlertAlternateReturn:
                [NSApp terminate:self];
                return;
                break;
            default:
                break;
        }
    }    
    _pref = [[Preferences alloc] init];
}

- (void) awakeFromNib{
	statusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength] retain];
	[statusItem setMenu:statusMenu];
	[statusItem setTitle:@"Shift"];
	[statusItem setHighlightMode:YES];
}

-(IBAction)showPreferences:(id)sender{
    if (!prefController) {
        prefController = [[PrefWindowController alloc]init];
    }
    [prefController showPreferences:sender];
    [NSApp activateIgnoringOtherApps:YES];
}

@end
