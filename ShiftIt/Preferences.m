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
		case 1:
			[(WindowSizer*)userData shiftToLeftHalf:NULL];
			break;
		case 2:
			[(WindowSizer*)userData shiftToRightHalf:NULL];
			break;
		case 3:
			[(WindowSizer*)userData shiftToTopHalf:NULL];
			break;
		case 4:
			[(WindowSizer*)userData shiftToBottomHalf:NULL];
			break;
		case 5:
			[(WindowSizer*)userData shiftToTopLeft:NULL];
			break;
		case 6:
			[(WindowSizer*)userData shiftToTopRight:NULL];
			break;
		case 7:
			[(WindowSizer*)userData shiftToBottomLeft:NULL];
			break;
		case 8:
			[(WindowSizer*)userData shiftToBottomRight:NULL];
			break;
		case 9:
			[(WindowSizer*)userData shiftToCenter:NULL];
			break;
		case 10:
			[(WindowSizer*)userData fullScreen:NULL];
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
        [self registerDefaults];
	}
	return self;
}

-(void)registerDefaults{
    [NSUserDefaults resetStandardUserDefaults];
    NSLog(@"Registering default");
	_userDefaultsValuesDict = [NSMutableDictionary dictionary];
	NSDictionary * leftHalf = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInt:(NSCommandKeyMask+NSAlternateKeyMask)],HotKeyModifers,
                                                [NSNumber numberWithUnsignedInt:123],HotKeyCodes,
                                                nil];
    
    [_userDefaultsValuesDict setObject:leftHalf forKey:@"leftHalf"];

    NSDictionary * rightHalf = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInt:(NSCommandKeyMask+NSAlternateKeyMask)],HotKeyModifers,
                               [NSNumber numberWithUnsignedInt:124],HotKeyCodes,
                               nil];
    
    [_userDefaultsValuesDict setObject:rightHalf forKey:@"rightHalf"];

    
    NSDictionary * topHalf = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInt:(NSCommandKeyMask+NSAlternateKeyMask)],HotKeyModifers,
                               [NSNumber numberWithUnsignedInt:126],HotKeyCodes,
                               nil];
    
    [_userDefaultsValuesDict setObject:topHalf forKey:@"topHalf"];

    
    NSDictionary * bottomhalf = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInt:(NSCommandKeyMask+NSAlternateKeyMask)],HotKeyModifers,
                               [NSNumber numberWithUnsignedInt:125],HotKeyCodes,
                               nil];
    
    [_userDefaultsValuesDict setObject:bottomhalf forKey:@"bottomHalf"];

    NSDictionary * topLeft = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInt:(NSCommandKeyMask+NSAlternateKeyMask+NSControlKeyMask)],HotKeyModifers,
                                 [NSNumber numberWithUnsignedInt:123],HotKeyCodes,
                                 nil];
    [_userDefaultsValuesDict setObject:topLeft forKey:@"topLeft"];

    NSDictionary * topRight = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInt:(NSCommandKeyMask+NSAlternateKeyMask+NSControlKeyMask)],HotKeyModifers,
                              [NSNumber numberWithUnsignedInt:126],HotKeyCodes,
                              nil];
    [_userDefaultsValuesDict setObject:topRight forKey:@"topRight"];

    NSDictionary * bottomLeft = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInt:(NSCommandKeyMask+NSAlternateKeyMask+NSControlKeyMask)],HotKeyModifers,
                              [NSNumber numberWithUnsignedInt:125],HotKeyCodes,
                              nil];
    [_userDefaultsValuesDict setObject:bottomLeft forKey:@"bottomLeft"];
    
    NSDictionary * bottomRight = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInt:(NSCommandKeyMask+NSAlternateKeyMask+NSControlKeyMask)],HotKeyModifers,
                              [NSNumber numberWithUnsignedInt:124],HotKeyCodes,
                              nil];
    [_userDefaultsValuesDict setObject:bottomRight forKey:@"bottomRight"];

    NSDictionary * fullScreen = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInt:(NSCommandKeyMask+NSAlternateKeyMask)],HotKeyModifers,
                                  [NSNumber numberWithUnsignedInt:3],HotKeyCodes,
                                  nil];
    [_userDefaultsValuesDict setObject:fullScreen forKey:@"fullScreen"];
    
    NSDictionary * center = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInt:(NSCommandKeyMask+NSAlternateKeyMask)],HotKeyModifers,
                                  [NSNumber numberWithUnsignedInt:8],HotKeyCodes,
                                  nil];
    [_userDefaultsValuesDict setObject:center forKey:@"center"];
    
	[_hKeyController registerHotKey:[[SIHotKey alloc]initWithIdentifier:1 keyCode:123 modCombo:[NSNumber numberWithUnsignedInt:(NSCommandKeyMask+NSAlternateKeyMask)]]];
	[_hKeyController registerHotKey:[[SIHotKey alloc]initWithIdentifier:2 keyCode:124 modCombo:[NSNumber numberWithUnsignedInt:(NSCommandKeyMask+NSAlternateKeyMask)]]];
	[_hKeyController registerHotKey:[[SIHotKey alloc]initWithIdentifier:3 keyCode:126 modCombo:[NSNumber numberWithUnsignedInt:(NSCommandKeyMask+NSAlternateKeyMask)]]];
	[_hKeyController registerHotKey:[[SIHotKey alloc]initWithIdentifier:4 keyCode:125 modCombo:[NSNumber numberWithUnsignedInt:(NSCommandKeyMask+NSAlternateKeyMask)]]];
	[_hKeyController registerHotKey:[[SIHotKey alloc]initWithIdentifier:5 keyCode:123 modCombo:[NSNumber numberWithUnsignedInt:(NSCommandKeyMask+NSAlternateKeyMask+NSControlKeyMask)]]];
	[_hKeyController registerHotKey:[[SIHotKey alloc]initWithIdentifier:6 keyCode:126 modCombo:[NSNumber numberWithUnsignedInt:(NSCommandKeyMask+NSAlternateKeyMask+NSControlKeyMask)]]];
	[_hKeyController registerHotKey:[[SIHotKey alloc]initWithIdentifier:7 keyCode:125 modCombo:[NSNumber numberWithUnsignedInt:(NSCommandKeyMask+NSAlternateKeyMask+NSControlKeyMask)]]];
	[_hKeyController registerHotKey:[[SIHotKey alloc]initWithIdentifier:8 keyCode:124 modCombo:[NSNumber numberWithUnsignedInt:(NSCommandKeyMask+NSAlternateKeyMask+NSControlKeyMask)]]];
	[_hKeyController registerHotKey:[[SIHotKey alloc]initWithIdentifier:9 keyCode:8 modCombo:[NSNumber numberWithUnsignedInt:(NSCommandKeyMask+NSAlternateKeyMask)]]];
	[_hKeyController registerHotKey:[[SIHotKey alloc]initWithIdentifier:10 keyCode:3 modCombo:[NSNumber numberWithUnsignedInt:(NSCommandKeyMask+NSAlternateKeyMask)]]];
	
    [_userDefaultsValuesDict setObject:[NSNumber numberWithBool:YES] forKey:@"shiftItstartLogin"];
    [_userDefaultsValuesDict setObject:[NSNumber numberWithBool:YES] forKey:@"shiftItshowMenu"];
	
	[[NSUserDefaults standardUserDefaults] registerDefaults:_userDefaultsValuesDict];
	[[NSUserDefaults standardUserDefaults] synchronize];
    
    NSArray *resettableUserDefaultsKeys;
    NSDictionary * initialValuesDict;
    resettableUserDefaultsKeys=[NSArray arrayWithObjects:@"leftHalf",@"topHalf",@"bottomHalf",@"rightHalf",@"bottomLeft",@"bottomRight",@"topLeft",@"topRight",@"fullScreen",@"center",nil];
	
    initialValuesDict=[[NSUserDefaults standardUserDefaults] dictionaryWithValuesForKeys:resettableUserDefaultsKeys];
    
    // Set the initial values in the shared user defaults controller
    [[NSUserDefaultsController sharedUserDefaultsController] setInitialValues:initialValuesDict];
	
    
}

-(void)modifyHotKey:(NSInteger)newKey modiferKeys:(NSInteger)modKeys key:(NSString*)keyCode{
	[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:newKey] forKey:[@"hkc" stringByAppendingString:keyCode]];
	[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:modKeys] forKey:[@"hkm" stringByAppendingString:keyCode]];
	[_hKeyController modifyHotKey:[[SIHotKey alloc]initWithIdentifier:[[_userDefaultsValuesDict objectForKey:keyCode] intValue] keyCode:newKey modCombo:[NSNumber numberWithUnsignedInt:modKeys]]];
	[[NSUserDefaults standardUserDefaults] synchronize];	
}

-(void)dealloc{
    [_winSizer release];
    [_hKeyController release];
	[_userDefaultsValuesDict release];
    [super dealloc];
}
@end
