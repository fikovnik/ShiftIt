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
@synthesize recorderCtlArray, buttonPressed, statusMenu;


-(id)init{
	hkContObject = [hKController getInstance];
    if ((self = [super initWithWindowNibName:@"PrefWindow"])) {
		NSLog(@"Registering default2");
    }
	
    return self;
}

-(void)windowDidLoad{
	self.recorderCtlArray = [[NSArray alloc] initWithObjects:
							 leftRecorderCtrl,
							 rightRecorderCtrl,
							 topRecorderCtrl,
							 bottomRecorderCtrl,
							 tlRecorderCtrl,
							 trRecorderCtrl,
							 blRecorderCtrl,
							 brRecorderCtrl,
							 fullScreenRecorderCtrl,
							 centerRecorderCtrl,
							 nil];
	
	buttonPressed = -1;
	[self updateRecorderCombos];

	NSString *versionString = [NSString stringWithFormat:@"v%@",[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];
	[versionLabel setStringValue:versionString];
}

-(BOOL)acceptsFirstResponder{
	return YES;
}

-(void)awakeFromNib{
    [tabView selectTabViewItemAtIndex:0];
}

-(IBAction)showPreferences:(id)sender{
    [[self window] center];
    [NSApp activateIgnoringOtherApps:YES];
    [[self window] makeKeyAndOrderFront:sender];    
}

#pragma mark -
#pragma mark Shortcut Recorder methods
//-(BOOL)shortcutRecorder:(SRRecorderControl *)aRecorder isKeyCode:(NSInteger)keyCode andFlagsTaken:(NSUInteger)flags reason:(NSString **)aReason{
//	
//	return YES;
//}

- (void)shortcutRecorder:(SRRecorderControl *)aRecorder keyComboDidChange:(KeyCombo)newKeyCombo{
	NSLog(@"%@", SRStringForCocoaModifierFlagsAndKeyCode(newKeyCombo.flags, newKeyCombo.code));
	buttonPressed = [recorderCtlArray indexOfObject:aRecorder];
	
	if(buttonPressed >= 0){
	
		//change the hotkey in NSUserDefaults
		NSString* modifiersPath = [[NSBundle mainBundle] pathForResource:@"ModifierDictStrings" ofType:@"plist"];
		NSArray *modifierKeys = [NSArray arrayWithContentsOfFile:modifiersPath];
		NSString* keycodesPath = [[NSBundle mainBundle] pathForResource:@"KeycodeDictKeys" ofType:@"plist"];
		NSArray *keycodeKeys = [NSArray arrayWithContentsOfFile:keycodesPath];
		
		[[NSUserDefaults standardUserDefaults] setInteger:newKeyCombo.flags forKey:[modifierKeys objectAtIndex:buttonPressed]];
		[[NSUserDefaults standardUserDefaults] setInteger:newKeyCombo.code forKey:[keycodeKeys objectAtIndex:buttonPressed]];
		[[NSUserDefaults standardUserDefaults] synchronize];
		
		//modify the hotkey
		SIHotKey *newHotKey = [[SIHotKey alloc] initWithIdentifier:buttonPressed 
														   keyCode:newKeyCombo.code
														  modCombo:newKeyCombo.flags];
		
		[hkContObject modifyHotKey:newHotKey];
		[newHotKey release];
		
		//set the key equivalent on the status menu item
		//must account for the horizontal lines in menu
		int menuIndex = buttonPressed;
		if(menuIndex > 3)
			menuIndex++;
		if(menuIndex > 8)
			menuIndex++;	
		
		[[statusMenu itemAtIndex:menuIndex] setKeyEquivalent:[SRStringForKeyCode(newKeyCombo.code) lowercaseString]];
		[[statusMenu itemAtIndex:menuIndex] setKeyEquivalentModifierMask:newKeyCombo.flags];
		
		buttonPressed = -1;
	}
}

-(void)updateRecorderCombos{
	NSString* modifiersPath = [[NSBundle mainBundle] pathForResource:@"ModifierDictStrings" ofType:@"plist"];
	NSArray *modifierKeys = [NSArray arrayWithContentsOfFile:modifiersPath];
	NSString* keycodesPath = [[NSBundle mainBundle] pathForResource:@"KeycodeDictKeys" ofType:@"plist"];
	NSArray *keycodeKeys = [NSArray arrayWithContentsOfFile:keycodesPath];
	NSUserDefaults *storage = [NSUserDefaults standardUserDefaults];
	
	for(int i=0; i<[recorderCtlArray count]; i++){
		KeyCombo combo;
		combo.code = [storage integerForKey:[keycodeKeys objectAtIndex:i]];
		combo.flags = [storage integerForKey:[modifierKeys objectAtIndex:i]];
		[[recorderCtlArray objectAtIndex:i] setKeyCombo:combo];
	}
}

-(void)dealloc{
	[recorderCtlArray release];
	[statusMenu release];
	[super dealloc];
}

@end
