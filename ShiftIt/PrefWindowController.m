//
//  PrefWindowController.m
//  ShiftIt
//
//  Created by Aravindkumar Rajendiran on 10-02-22.
//  Copyright 2010 Grapewave. All rights reserved.
//

#import "PrefWindowController.h"


@implementation PrefWindowController

-(id)init{
    if ((self = [super initWithWindowNibName:@"PrefWindow"])) {
            NSLog(@"Registering default2");
        
    }
    return self;
}

-(void)awakeFromNib{
    [tabView selectTabViewItemAtIndex:0];
}

-(IBAction)openAtLogin:(id)sender{
    if([sender state] == NSOnState){
        [Preferences registerForLogin:YES];
    }else {
        [Preferences registerForLogin:NO];
    }
}

-(IBAction)savePreferences:(id)sender{
    
    
}

-(IBAction)showPreferences:(id)sender{
    [[self window] center];
    [NSApp activateIgnoringOtherApps:YES];
    [[self window] makeKeyAndOrderFront:sender];
    
    
}
-(IBAction)closePreferences:(id)sender{
    [[self window] performClose:sender];
}


- (id)windowWillReturnFieldEditor:(NSWindow *)sender toObject:(id)client {
    if ([client isKindOfClass:[GTMHotKeyTextField class]]) {
        return [GTMHotKeyFieldEditor sharedHotKeyFieldEditor];
    } else {
        return nil;
    }
}


@end
