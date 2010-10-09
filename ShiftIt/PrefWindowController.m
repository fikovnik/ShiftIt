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

@synthesize recorderCtlArray = recorderCtlArray_;
@synthesize buttonPressed = buttonPressed_;
@synthesize statusMenu= statusMenu_;

-(id)init{
	hkContObject_ = [hKController getInstance];
    if ((self = [super initWithWindowNibName:@"PrefWindow"])) {
		NSLog(@"Registering default2");
    }
	
    return self;
}

-(void)windowDidLoad{
	self.recorderCtlArray = [[NSArray alloc] initWithObjects:
							 leftRecorderCtrl_,
							 rightRecorderCtrl_,
							 topRecorderCtrl_,
							 bottomRecorderCtrl_,
							 tlRecorderCtrl_,
							 trRecorderCtrl_,
							 blRecorderCtrl_,
							 brRecorderCtrl_,
							 fullScreenRecorderCtrl_,
							 centerRecorderCtrl_,
							 nil];
	
	buttonPressed_ = -1;
	[self updateRecorderCombos];

	NSString *versionString = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
	[versionLabel_ setStringValue:versionString];
}

-(BOOL)acceptsFirstResponder{
	return YES;
}

-(void)awakeFromNib{
    [tabView_ selectTabViewItemAtIndex:0];
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
	buttonPressed_ = [recorderCtlArray_ indexOfObject:aRecorder];
	
	if(buttonPressed_ >= 0){
	
		//change the hotkey in NSUserDefaults
		NSString* modifiersPath = [[NSBundle mainBundle] pathForResource:@"ModifierDictStrings" ofType:@"plist"];
		NSArray *modifierKeys = [NSArray arrayWithContentsOfFile:modifiersPath];
		NSString* keycodesPath = [[NSBundle mainBundle] pathForResource:@"KeycodeDictKeys" ofType:@"plist"];
		NSArray *keycodeKeys = [NSArray arrayWithContentsOfFile:keycodesPath];
		
		[[NSUserDefaults standardUserDefaults] setInteger:newKeyCombo.flags forKey:[modifierKeys objectAtIndex:buttonPressed_]];
		[[NSUserDefaults standardUserDefaults] setInteger:newKeyCombo.code forKey:[keycodeKeys objectAtIndex:buttonPressed_]];
		[[NSUserDefaults standardUserDefaults] synchronize];
		
		//modify the hotkey
		SIHotKey *newHotKey = [[SIHotKey alloc] initWithIdentifier:buttonPressed_ 
														   keyCode:newKeyCombo.code
														  modCombo:newKeyCombo.flags];
		
		[hkContObject_ modifyHotKey:newHotKey];
		[newHotKey release];
		
		//set the key equivalent on the status menu item
		//must account for the horizontal lines in menu
		int menuIndex = buttonPressed_;
		if(menuIndex > 3)
			menuIndex++;
		if(menuIndex > 8)
			menuIndex++;	
		
		[[statusMenu_ itemAtIndex:menuIndex] setKeyEquivalent:[SRStringForKeyCode(newKeyCombo.code) lowercaseString]];
		[[statusMenu_ itemAtIndex:menuIndex] setKeyEquivalentModifierMask:newKeyCombo.flags];
		
		buttonPressed_ = -1;
	}
}

-(void)updateRecorderCombos{
	NSString* modifiersPath = [[NSBundle mainBundle] pathForResource:@"ModifierDictStrings" ofType:@"plist"];
	NSArray *modifierKeys = [NSArray arrayWithContentsOfFile:modifiersPath];
	NSString* keycodesPath = [[NSBundle mainBundle] pathForResource:@"KeycodeDictKeys" ofType:@"plist"];
	NSArray *keycodeKeys = [NSArray arrayWithContentsOfFile:keycodesPath];
	NSUserDefaults *storage = [NSUserDefaults standardUserDefaults];
	
	for(int i=0; i<[recorderCtlArray_ count]; i++){
		KeyCombo combo;
		combo.code = [storage integerForKey:[keycodeKeys objectAtIndex:i]];
		combo.flags = [storage integerForKey:[modifierKeys objectAtIndex:i]];
		[[recorderCtlArray_ objectAtIndex:i] setKeyCombo:combo];
	}
}

-(void)dealloc{
	[recorderCtlArray_ release];
	[statusMenu_ release];
	[super dealloc];
}

@end
