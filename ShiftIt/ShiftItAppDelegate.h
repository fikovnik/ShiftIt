//
//  ShiftItAppDelegate.h
//  ShiftIt
//
//  Created by Aravindkumar Rajendiran on 10-02-13.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PrefWindowController.h"

@interface ShiftItAppDelegate : NSObject {
    PrefWindowController * prefController;
    Preferences * _pref;
	IBOutlet NSMenu *statusMenu;
	NSStatusItem *statusItem;
}

-(IBAction)showPreferences:(id)sender;
-(void)updateMenuBarIcon;
-(void)registerForLogin;
@end
