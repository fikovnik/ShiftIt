/*
 ShiftIt: Resize windows with Hotkeys
 Copyright (C) 2010  Aravind
 
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
