//
//  ShiftItAppDelegate.h
//  ShiftIt
//
//  Created by Aravindkumar Rajendiran on 10-02-13.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PrefWindow.h"
#import "Preferences.h"

@interface ShiftItAppDelegate : NSObject {
    PrefWindow *window;
    IBOutlet NSMenu *statusMenu;
	NSStatusItem *statusItem;
    Preferences * _pref;
}

@property (assign) IBOutlet PrefWindow *window;

-(IBAction)showPreferences:(id)sender;
@end
