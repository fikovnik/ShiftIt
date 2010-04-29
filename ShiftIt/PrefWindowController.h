//
//  PrefWindowController.h
//  ShiftIt
//
//  Created by Aravindkumar Rajendiran on 10-02-22.
//  Copyright 2010 Grapewave. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#include "Preferences.h"

@interface PrefWindowController : NSWindowController {
    IBOutlet NSTextField * _top;
    IBOutlet NSTextField * _bottom;
    IBOutlet NSTextField * _left;
    IBOutlet NSTextField * _right;
    
    IBOutlet NSTextField * _topLeft;
    IBOutlet NSTextField * _topRight;
    IBOutlet NSTextField * _bottomLeft;
    IBOutlet NSTextField * _bottomRight;
    
    IBOutlet NSTextField * _fullScreen;
    IBOutlet NSTextField * _center;
    
    IBOutlet NSButton * _openAtLogin;
    IBOutlet NSTabView * tabView;
}

-(IBAction)savePreferences:(id)sender;
-(IBAction)closePreferences:(id)sender;
-(IBAction)showPreferences:(id)sender;
@end
