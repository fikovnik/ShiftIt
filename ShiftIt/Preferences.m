//
//  Preferences.m
//  ShiftIt
//
//  Created by Aravindkumar Rajendiran on 10-02-14.
//  Copyright 2010 Grapewave. All rights reserved.
//

#import "Preferences.h"
#import "HotKeyController.h"

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
	_userDefaultsValuesDict = [NSMutableDictionary dictionary];
    
	[_userDefaultsValuesDict setObject:[NSNumber numberWithInt:11] forKey:@"Q"];
	[_userDefaultsValuesDict setObject:[NSNumber numberWithInt:13] forKey:@"hkcq"];
	[_userDefaultsValuesDict setObject:[NSNumber numberWithInt:cmdKey] forKey:@"hkmQ"];
	[_hKeyController registerHotKey:[[SIHotKey alloc]initWithIdentifier:11 keyCode:13 modCombo:(cmdKey)]];
	
	[_userDefaultsValuesDict setObject:[NSNumber numberWithInt:1] forKey:@"L"];
	[_userDefaultsValuesDict setObject:[NSNumber numberWithInt:123] forKey:@"hkcL"];
	[_userDefaultsValuesDict setObject:[NSNumber numberWithInt:cmdKey+optionKey] forKey:@"hkmL"];
	[_hKeyController registerHotKey:[[SIHotKey alloc]initWithIdentifier:1 keyCode:123 modCombo:(cmdKey+optionKey)]];
    
	[_userDefaultsValuesDict setObject:[NSNumber numberWithInt:2] forKey:@"R"];
	[_userDefaultsValuesDict setObject:[NSNumber numberWithInt:124] forKey:@"hkcR"];
	[_userDefaultsValuesDict setObject:[NSNumber numberWithInt:cmdKey+optionKey] forKey:@"hkmR"];
	[_hKeyController registerHotKey:[[SIHotKey alloc]initWithIdentifier:2 keyCode:124 modCombo:(cmdKey+optionKey)]];
    
	[_userDefaultsValuesDict setObject:[NSNumber numberWithInt:3] forKey:@"T"];
	[_userDefaultsValuesDict setObject:[NSNumber numberWithInt:126] forKey:@"hkcT"];
	[_userDefaultsValuesDict setObject:[NSNumber numberWithInt:cmdKey+optionKey] forKey:@"hkmT"];
	[_hKeyController registerHotKey:[[SIHotKey alloc]initWithIdentifier:3 keyCode:126 modCombo:(cmdKey+optionKey)]];
    
	[_userDefaultsValuesDict setObject:[NSNumber numberWithInt:4] forKey:@"B"];
	[_userDefaultsValuesDict setObject:[NSNumber numberWithInt:125] forKey:@"hkcB"];
	[_userDefaultsValuesDict setObject:[NSNumber numberWithInt:cmdKey+optionKey] forKey:@"hkmB"];
	[_hKeyController registerHotKey:[[SIHotKey alloc]initWithIdentifier:4 keyCode:125 modCombo:(cmdKey+optionKey)]];
	
	[_userDefaultsValuesDict setObject:[NSNumber numberWithInt:5] forKey:@"TL"];
	[_userDefaultsValuesDict setObject:[NSNumber numberWithInt:123] forKey:@"hkcTL"];
	[_userDefaultsValuesDict setObject:[NSNumber numberWithInt:cmdKey+optionKey+controlKey] forKey:@"hkmTL"];
	[_hKeyController registerHotKey:[[SIHotKey alloc]initWithIdentifier:5 keyCode:123 modCombo:(cmdKey+optionKey+controlKey)]];
    
	[_userDefaultsValuesDict setObject:[NSNumber numberWithInt:6] forKey:@"TR"];
	[_userDefaultsValuesDict setObject:[NSNumber numberWithInt:126] forKey:@"hkcTR"];
	[_userDefaultsValuesDict setObject:[NSNumber numberWithInt:cmdKey+optionKey+controlKey] forKey:@"hkmTR"];
	[_hKeyController registerHotKey:[[SIHotKey alloc]initWithIdentifier:6 keyCode:126 modCombo:(cmdKey+optionKey+controlKey)]];
    
	[_userDefaultsValuesDict setObject:[NSNumber numberWithInt:7] forKey:@"BL"];
	[_userDefaultsValuesDict setObject:[NSNumber numberWithInt:125] forKey:@"hkcBL"];
	[_userDefaultsValuesDict setObject:[NSNumber numberWithInt:cmdKey+optionKey+controlKey] forKey:@"hkmBL"];
	[_hKeyController registerHotKey:[[SIHotKey alloc]initWithIdentifier:7 keyCode:125 modCombo:(cmdKey+optionKey+controlKey)]];
    
	[_userDefaultsValuesDict setObject:[NSNumber numberWithInt:8] forKey:@"BR"];
	[_userDefaultsValuesDict setObject:[NSNumber numberWithInt:124] forKey:@"hkcBR"];
	[_userDefaultsValuesDict setObject:[NSNumber numberWithInt:cmdKey+optionKey+controlKey] forKey:@"hkmBR"];
	[_hKeyController registerHotKey:[[SIHotKey alloc]initWithIdentifier:8 keyCode:124 modCombo:(cmdKey+optionKey+controlKey)]];
    
	[_userDefaultsValuesDict setObject:[NSNumber numberWithInt:9] forKey:@"C"];
	[_userDefaultsValuesDict setObject:[NSNumber numberWithInt:8] forKey:@"hkcC"];
	[_userDefaultsValuesDict setObject:[NSNumber numberWithInt:cmdKey+optionKey] forKey:@"hkmC"];
	[_hKeyController registerHotKey:[[SIHotKey alloc]initWithIdentifier:9 keyCode:8 modCombo:(cmdKey+optionKey)]];	
    
	[_userDefaultsValuesDict setObject:[NSNumber numberWithInt:10] forKey:@"F"];
	[_userDefaultsValuesDict setObject:[NSNumber numberWithInt:3] forKey:@"hkcF"];
	[_userDefaultsValuesDict setObject:[NSNumber numberWithInt:cmdKey+optionKey] forKey:@"hkmF"];
	[_hKeyController registerHotKey:[[SIHotKey alloc]initWithIdentifier:10 keyCode:3 modCombo:(cmdKey+optionKey)]];
	
	[[NSUserDefaults standardUserDefaults] registerDefaults:_userDefaultsValuesDict];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

-(void)modifyHotKey:(NSInteger)newKey modiferKeys:(NSInteger)modKeys key:(NSString*)keyCode{
	[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:newKey] forKey:[@"hkc" stringByAppendingString:keyCode]];
	[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:modKeys] forKey:[@"hkm" stringByAppendingString:keyCode]];
	[_hKeyController modifyHotKey:[[SIHotKey alloc]initWithIdentifier:[[_userDefaultsValuesDict objectForKey:keyCode] intValue] keyCode:newKey modCombo:modKeys]];
	[[NSUserDefaults standardUserDefaults] synchronize];	
}

-(void)dealloc{
    [_winSizer release];
    [_hKeyController release];
	[_userDefaultsValuesDict release];
    [super dealloc];
}
@end
