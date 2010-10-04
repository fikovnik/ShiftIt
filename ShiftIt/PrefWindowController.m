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

@synthesize hotKeyButtonMatrix, modifiersString, textFieldArray, buttonPressed;
@synthesize topField,bottomField,leftField,rightField;
@synthesize tlField,trField,blField,brField,fullScreenField,centerField;
@synthesize statusMenu;



-(id)init{
	hkContObject = [hKController getInstance];
    if ((self = [super initWithWindowNibName:@"PrefWindow"])) {
		NSLog(@"Registering default2");
    }
	
    return self;
}

-(void)windowDidLoad{
	self.textFieldArray = [[NSArray alloc] initWithObjects:
						   self.leftField,
						   self.rightField,
						   self.topField,
						   self.bottomField,
						   self.tlField,
						   self.trField,
						   self.blField,
						   self.brField,
						   self.fullScreenField,
						   self.centerField,
						   nil];
	
	buttonPressed = -1;
	[self updateTextFields];
}

-(BOOL)acceptsFirstResponder{
	return YES;
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

- (void)flagsChanged:(NSEvent *)theEvent{
	if(buttonPressed == -1)
		return;
	
	self.modifiersString = [self modifierKeysStringForFlags:[theEvent modifierFlags]];
	
	if(buttonPressed >= 0)
		[[textFieldArray objectAtIndex:buttonPressed] setStringValue:self.modifiersString];
}

- (void)keyDown:(NSEvent *)theEvent {
	NSUInteger modifiers = [theEvent modifierFlags];
	if(modifiers == 0 || buttonPressed == -1)
		return;
	
	NSMutableString *hotKeyString = [[NSMutableString alloc] initWithString:self.modifiersString];
	
	unichar keyChar = [[theEvent charactersIgnoringModifiers] characterAtIndex:0];
	if (modifiers & NSNumericPadKeyMask && keyChar == NSLeftArrowFunctionKey ) 
		[hotKeyString appendString:@"←"];
	else if (modifiers & NSNumericPadKeyMask && keyChar == NSRightArrowFunctionKey ) 
		[hotKeyString appendString:@"→"];
	else if (modifiers & NSNumericPadKeyMask && keyChar == NSUpArrowFunctionKey ) 
		[hotKeyString appendString:@"↑"];
	else if (modifiers & NSNumericPadKeyMask && keyChar == NSDownArrowFunctionKey ) 
		[hotKeyString appendString:@"↓"];
	else 
		[hotKeyString appendString:[theEvent charactersIgnoringModifiers]];
	
	if(buttonPressed >= 0){
		[[textFieldArray objectAtIndex:buttonPressed] setStringValue:[hotKeyString uppercaseString]];

		//change the hotkey in NSUserDefaults
		NSString* modifiersPath = [[NSBundle mainBundle] pathForResource:@"ModifierDictStrings" ofType:@"plist"];
		NSArray *modifierKeys = [NSArray arrayWithContentsOfFile:modifiersPath];
		NSString* keycodesPath = [[NSBundle mainBundle] pathForResource:@"KeycodeDictKeys" ofType:@"plist"];
		NSArray *keycodeKeys = [NSArray arrayWithContentsOfFile:keycodesPath];
		
		[[NSUserDefaults standardUserDefaults] setInteger:modifiers forKey:[modifierKeys objectAtIndex:buttonPressed]];
		[[NSUserDefaults standardUserDefaults] setInteger:theEvent.keyCode forKey:[keycodeKeys objectAtIndex:buttonPressed]];
		[[NSUserDefaults standardUserDefaults] synchronize];
		
		//register the new hotkey
		SIHotKey *newHotKey = [[SIHotKey alloc] initWithIdentifier:buttonPressed 
														   keyCode:theEvent.keyCode
														  modCombo:modifiers];
		
		[hkContObject registerHotKey:newHotKey];
		[newHotKey release];
		
		//set the key equivalent on the status menu item
		//must account for the horizontal lines in menu
		if(buttonPressed > 3)
			buttonPressed++;
		if(buttonPressed > 7)
			buttonPressed++;
		
		[[statusMenu itemAtIndex:buttonPressed] setKeyEquivalent:[hotKeyString substringWithRange:NSMakeRange([hotKeyString length]-1, 1)] ];
		[[statusMenu itemAtIndex:buttonPressed] setKeyEquivalentModifierMask:modifiers];
		
		buttonPressed = -1;
	}
	
	[self enableButtons];
	[hotKeyString release];
}


-(IBAction)changeHotkey:(id)sender{
	buttonPressed = [hotKeyButtonMatrix selectedRow];
	
	//Unregister old hotkey incase user wants to use the same one
	[hkContObject unregisterHotKey:[[hkContObject _hotKeys] objectForKey:[NSNumber numberWithInt:buttonPressed]]];
	
	[[textFieldArray objectAtIndex:buttonPressed] setStringValue:@"Press Keys..."];
	[self disableButtons];
}

-(NSMutableString *)modifierKeysStringForFlags:(NSUInteger)modifierFlags{
	NSMutableString *modifierKeysString = [[[NSMutableString alloc] initWithString:@""] autorelease];
	
	if(modifierFlags & NSControlKeyMask)
		[modifierKeysString appendString:@"⌃"];
	
	if(modifierFlags & NSAlternateKeyMask)
		[modifierKeysString appendString:@"⌥"];
	
	if(modifierFlags & NSShiftKeyMask)
		[modifierKeysString appendString:@"⇧"];
	
	if(modifierFlags & NSCommandKeyMask)
		[modifierKeysString appendString:@"⌘"];
	
	return modifierKeysString;
}

-(void)disableButtons{
	[hotKeyButtonMatrix setEnabled:NO];
	[hotKeyButtonMatrix setAlphaValue:0.5];
}

-(void)enableButtons{
	[hotKeyButtonMatrix setEnabled:YES];
	[hotKeyButtonMatrix setAlphaValue:1.0];
}

-(void)updateTextFields{
	NSString* modifiersPath = [[NSBundle mainBundle] pathForResource:@"ModifierDictStrings" ofType:@"plist"];
	NSArray *modifierKeys = [NSArray arrayWithContentsOfFile:modifiersPath];
	
	NSString* keycodesPath = [[NSBundle mainBundle] pathForResource:@"KeycodeDictKeys" ofType:@"plist"];
	NSArray *keycodeKeys = [NSArray arrayWithContentsOfFile:keycodesPath];
	
	for(int i=0; i < [modifierKeys count]; i++){
		NSString *modifierKey = [modifierKeys objectAtIndex:i];
		NSString *keycodeKey = [keycodeKeys objectAtIndex:i];
		
		//start off with the string of modifiers
		NSInteger modifiers = [[NSUserDefaults standardUserDefaults] integerForKey:modifierKey];
		NSMutableString *hotKeyString = [self modifierKeysStringForFlags:modifiers];
		
		//convert virtual keycode to character--
		// strange code but I can't seem to find any other way to do it
		UInt32 deadKeyState = 0;
		UniCharCount actualCount = 0;
		UniChar baseChar;
		TISInputSourceRef sourceRef = TISCopyCurrentKeyboardLayoutInputSource();
		CFDataRef keyLayoutPtr = (CFDataRef)TISGetInputSourceProperty( sourceRef, kTISPropertyUnicodeKeyLayoutData); 
		CFRelease( sourceRef);
		UCKeyTranslate( (UCKeyboardLayout*)CFDataGetBytePtr(keyLayoutPtr),
					   [[NSUserDefaults standardUserDefaults] integerForKey:keycodeKey], //<--virtual keycode
					   kUCKeyActionDown,
					   0,
					   LMGetKbdLast(),
					   kUCKeyTranslateNoDeadKeysBit,
					   &deadKeyState,
					   1,
					   &actualCount,
					   &baseChar);
		
		//arrows don't count as characters-- they're technically modifiers
		// --must check the modifiers flags for the arrow keys
		[[NSUserDefaults standardUserDefaults] synchronize];
		if (modifiers & NSNumericPadKeyMask) {
			NSInteger keyCode = [[NSUserDefaults standardUserDefaults] integerForKey:keycodeKey];
			
			if (keyCode == kVK_LeftArrow ) 
				[hotKeyString appendString:@"←"];
			else if (keyCode == kVK_RightArrow ) 
				[hotKeyString appendString:@"→"];
			else if (keyCode == kVK_UpArrow ) 
				[hotKeyString appendString:@"↑"];
			else if (keyCode == kVK_DownArrow ) 
				[hotKeyString appendString:@"↓"];
		}else 
			[hotKeyString appendFormat:@"%c",baseChar];
		
		//append key equivalent character
		[[textFieldArray objectAtIndex:i] setStringValue:[hotKeyString uppercaseString]];
	}
}

-(void)dealloc{
	[hotKeyButtonMatrix release];
	[modifiersString release];	
	[textFieldArray release];	
	[super dealloc];
}

@end
