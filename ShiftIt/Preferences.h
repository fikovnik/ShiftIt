//
//  Preferences.h
//  ShiftIt
//
//  Created by Aravindkumar Rajendiran on 10-02-14.
//  Copyright 2010 Grapewave. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "hKController.h"
#import "WindowSizer.h"

#define HotKeyModifers @"Modifiers"
#define HotKeyCodes @"Key Code"
@interface Preferences : NSObject {
    hKController * _hKeyController;
	NSMutableDictionary * _userDefaultsValuesDict;
    WindowSizer * _winSizer;
    EventTypeSpec _eventType;
}
-(void)modifyHotKey:(NSInteger)newKey modiferKeys:(NSInteger)modKeys key:(NSString*)keyCode;
-(void)registerDefaults;
+(void)registerForLogin:(BOOL)login;
@end
