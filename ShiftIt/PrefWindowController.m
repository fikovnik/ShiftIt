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

@end
