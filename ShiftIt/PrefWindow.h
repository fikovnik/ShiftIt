//
//  PrefWindow.h
//  ShiftIt
//
//  Created by Aravindkumar Rajendiran on 10-02-13.
//  Copyright 2010 Grapewave. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface PrefWindow : NSWindow {
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
}

-(void)registerForLogin:(BOOL)login;
-(IBAction)openAtLogin:(id)sender;
-(IBAction)savePreferences:(id)sender;

@end
