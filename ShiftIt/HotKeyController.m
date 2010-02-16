//
//  HotKeyController.m
//  ShiftIt
//
//  Created by Aravindkumar Rajendiran on 10-02-13.
//  Copyright 2010 Aravindkumar. All rights reserved.
//

#import "HotKeyController.h"


@implementation HotKeyController
static id _hkController = nil;

+(id)getInstance{
	if(_hkController == nil){
		_hkController = [[HotKeyController alloc]init];
	}
	return _hkController;
}

-(id)init{
	if(self == [super init]){
		_hotKeys = [[NSMutableDictionary alloc] init];
	}
	return self;
}

-(void)dealloc{
	[_hotKeys release];
	[super dealloc];
}


-(BOOL)registerHotKey:(SIHotKey*)hotKey{
	OSStatus error;
	EventHotKeyID hotKeyID;
	EventHotKeyRef hotKeyRef;
	
	hotKeyID.signature='SI';
	hotKeyID.id	= hotKey.hotKeyId;
	
	error = RegisterEventHotKey([hotKey keyCode], [hotKey modifierCombo], hotKeyID, GetEventDispatcherTarget(), 0, &hotKeyRef);
	
	if(error){
		return FALSE;
	}
	
	[hotKey setHotKeyRef:hotKeyRef];
	[_hotKeys setObject:hotKey forKey:[NSNumber numberWithInt:[hotKey hotKeyId]]];
	
	return TRUE;
}

-(BOOL)unregisterHotKey:(SIHotKey*)hotKey{
	OSStatus error;
	EventHotKeyRef hotKeyRef = [hotKey hotKeyRef];
	error = UnregisterEventHotKey(hotKeyRef);
	if(error){
		return FALSE;
	}
	[_hotKeys removeObjectForKey:[NSNumber numberWithInt:[hotKey hotKeyId]]];
	return TRUE;
}

-(BOOL)modifyHotKey:(SIHotKey*)hotKey{
	BOOL noError;
	noError = [self unregisterHotKey:[_hotKeys objectForKey:[NSNumber numberWithInt:[hotKey hotKeyId]]]];
	if(noError){
		noError = [self registerHotKey:hotKey];
	}
	return !noError;
}


@end
