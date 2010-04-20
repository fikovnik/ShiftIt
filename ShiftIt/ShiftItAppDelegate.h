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
    IBOutlet NSMenu *statusMenu;
	NSStatusItem *statusItem;
    Preferences * _pref;
}

-(IBAction)showPreferences:(id)sender;
@end
