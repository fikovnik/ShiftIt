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


#import "Preferences.h"

OSStatus winSizer(EventHandlerCallRef nextHandler,EventRef theEvent,void *userData){
	//Do something once the key is pressed
	EventHotKeyID hotKeyID;
	GetEventParameter(theEvent,kEventParamDirectObject,typeEventHotKeyID,NULL,sizeof(hotKeyID),NULL,&hotKeyID);
	int temphotKeyId = hotKeyID.id;
	switch (temphotKeyId) {
		case 0:
			[(WindowSizer*)userData shiftToLeftHalf:NULL];
			break;
		case 1:
			[(WindowSizer*)userData shiftToRightHalf:NULL];
			break;
		case 2:
			[(WindowSizer*)userData shiftToTopHalf:NULL];
			break;
		case 3:
			[(WindowSizer*)userData shiftToBottomHalf:NULL];
			break;
		case 4:
			[(WindowSizer*)userData shiftToTopLeft:NULL];
			break;
		case 5:
			[(WindowSizer*)userData shiftToTopRight:NULL];
			break;
		case 6:
			[(WindowSizer*)userData shiftToBottomLeft:NULL];
			break;
		case 7:
			[(WindowSizer*)userData shiftToBottomRight:NULL];
			break;
		case 8:
			[(WindowSizer*)userData fullScreen:NULL];
			break;
		case 9:
			[(WindowSizer*)userData shiftToCenter:NULL];
			break;
		default:
			break;
	}	
	return noErr;
}

@implementation Preferences

-(id)init{
	if(self == [super init]){
		_hKeyController = [hKController getInstance];
		_winSizer = [[WindowSizer alloc] init];
		_eventType.eventClass = kEventClassKeyboard;
		_eventType.eventKind = kEventHotKeyPressed;
		InstallApplicationEventHandler(&winSizer,1,&_eventType,_winSizer,NULL);
		
		if ( ![[NSUserDefaults standardUserDefaults] boolForKey:@"userDefaultsCleared"] ) {
			[self clearUserDefaults];
			[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"userDefaultsCleared"];
		}	
		
		[self registerHotKeys];
	}
	

	
	return self;
}

-(void)registerHotKeys{
	NSUserDefaults *storage = [NSUserDefaults standardUserDefaults];

	if (![storage boolForKey:@"defaultsRegistered"]) {
		[NSUserDefaults resetStandardUserDefaults];
		NSLog(@"Registering default");
		
		[storage setInteger:kVK_LeftArrow forKey:@"leftKeyCode"];
		[storage setInteger:(NSCommandKeyMask+NSAlternateKeyMask+NSControlKeyMask+NSNumericPadKeyMask) forKey:@"leftModifiers"];
		
		[storage setInteger:kVK_RightArrow forKey:@"rightKeyCode"];
		[storage setInteger:(NSCommandKeyMask+NSAlternateKeyMask+NSControlKeyMask+NSNumericPadKeyMask) forKey:@"rightModifiers"];

		[storage setInteger:kVK_UpArrow forKey:@"topKeyCode"];
		[storage setInteger:(NSCommandKeyMask+NSAlternateKeyMask+NSControlKeyMask+NSNumericPadKeyMask) forKey:@"topModifiers"];

		[storage setInteger:kVK_DownArrow forKey:@"bottomKeyCode"];
		[storage setInteger:(NSCommandKeyMask+NSAlternateKeyMask+NSControlKeyMask+NSNumericPadKeyMask) forKey:@"bottomModifiers"];

		
		[storage setInteger:kVK_ANSI_1 forKey:@"tlKeyCode"];
		[storage setInteger:(NSCommandKeyMask+NSAlternateKeyMask+NSControlKeyMask) forKey:@"tlModifiers"];

		[storage setInteger:kVK_ANSI_2 forKey:@"trKeyCode"];
		[storage setInteger:(NSCommandKeyMask+NSAlternateKeyMask+NSControlKeyMask) forKey:@"trModifiers"];

		[storage setInteger:kVK_ANSI_3 forKey:@"blKeyCode"];
		[storage setInteger:(NSCommandKeyMask+NSAlternateKeyMask+NSControlKeyMask) forKey:@"blModifiers"];

		[storage setInteger:kVK_ANSI_4 forKey:@"brKeyCode"];
		[storage setInteger:(NSCommandKeyMask+NSAlternateKeyMask+NSControlKeyMask) forKey:@"brModifiers"];

		
		[storage setInteger:kVK_ANSI_F forKey:@"fullscreenKeyCode"];
		[storage setInteger:(NSCommandKeyMask+NSAlternateKeyMask+NSControlKeyMask) forKey:@"fullscreenModifiers"];

		[storage setInteger:kVK_ANSI_C forKey:@"centerKeyCode"];
		[storage setInteger:(NSCommandKeyMask+NSAlternateKeyMask+NSControlKeyMask) forKey:@"centerModifiers"];
	
		[storage setBool:YES forKey:@"shiftItstartLogin"];
		[storage setBool:YES forKey:@"shiftItshowMenu"];
		
		[storage setBool:YES forKey:@"defaultsRegistered"];
		
	}	
	
	[storage synchronize];
	
	[_hKeyController registerHotKey:[[[SIHotKey alloc]initWithIdentifier:0 keyCode:[storage integerForKey:@"leftKeyCode"] modCombo:[storage integerForKey:@"leftModifiers"]] autorelease]];
	[_hKeyController registerHotKey:[[[SIHotKey alloc]initWithIdentifier:1 keyCode:[storage integerForKey:@"rightKeyCode"] modCombo:[storage integerForKey:@"rightModifiers"]] autorelease]];
	[_hKeyController registerHotKey:[[[SIHotKey alloc]initWithIdentifier:2 keyCode:[storage integerForKey:@"topKeyCode"] modCombo:[storage integerForKey:@"topModifiers"]] autorelease]];
	[_hKeyController registerHotKey:[[[SIHotKey alloc]initWithIdentifier:3 keyCode:[storage integerForKey:@"bottomKeyCode"] modCombo:[storage integerForKey:@"bottomModifiers"]] autorelease]];
	[_hKeyController registerHotKey:[[[SIHotKey alloc]initWithIdentifier:4 keyCode:[storage integerForKey:@"tlKeyCode"] modCombo:[storage integerForKey:@"tlModifiers"]] autorelease]];
	[_hKeyController registerHotKey:[[[SIHotKey alloc]initWithIdentifier:5 keyCode:[storage integerForKey:@"trKeyCode"] modCombo:[storage integerForKey:@"trModifiers"]] autorelease]];
	[_hKeyController registerHotKey:[[[SIHotKey alloc]initWithIdentifier:6 keyCode:[storage integerForKey:@"blKeyCode"] modCombo:[storage integerForKey:@"blModifiers"]] autorelease]];
	[_hKeyController registerHotKey:[[[SIHotKey alloc]initWithIdentifier:7 keyCode:[storage integerForKey:@"brKeyCode"] modCombo:[storage integerForKey:@"brModifiers"]] autorelease]];
	[_hKeyController registerHotKey:[[[SIHotKey alloc]initWithIdentifier:8 keyCode:[storage integerForKey:@"fullscreenKeyCode"] modCombo:[storage integerForKey:@"fullscreenModifiers"]] autorelease]];
	[_hKeyController registerHotKey:[[[SIHotKey alloc]initWithIdentifier:9 keyCode:[storage integerForKey:@"centerKeyCode"] modCombo:[storage integerForKey:@"centerModifiers"]] autorelease]];
    
}

-(void)modifyHotKey:(NSInteger)newKey modiferKeys:(NSInteger)modKeys key:(NSString*)keyCode{
	[[NSUserDefaults standardUserDefaults] setInteger:newKey forKey:[@"hkc" stringByAppendingString:keyCode]];
	[[NSUserDefaults standardUserDefaults] setInteger:modKeys forKey:[@"hkm" stringByAppendingString:keyCode]];
	[_hKeyController modifyHotKey:[[SIHotKey alloc]initWithIdentifier:[[_userDefaultsValuesDict objectForKey:keyCode] intValue] keyCode:newKey modCombo:modKeys]];
	[[NSUserDefaults standardUserDefaults] synchronize];	
}

-(void)clearUserDefaults{
	//Uncomment these lines to clear out the NSUserDefaults
	[[NSUserDefaults standardUserDefaults] removePersistentDomainForName:[[NSBundle mainBundle] bundleIdentifier]];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

-(void)dealloc{
    [_winSizer release];
    [_hKeyController release];
	[_userDefaultsValuesDict release];
    [super dealloc];
}
@end
