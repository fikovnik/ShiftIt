//
//  SIHotKey.m
//  ShiftIt
//
//  Created by Aravindkumar Rajendiran on 10-02-14.
//  Copyright 2010 Grapewave. All rights reserved.
//

#import "SIHotKey.h"


@implementation SIHotKey

-(id)initWithIdentifier:(NSInteger)identifier keyCode:(NSInteger)keyCode modCombo:(NSUInteger)modCombo{
	if(self ==[super init]){
		_hotKeyId = identifier;
		_keyCode = keyCode;
		_modifierCombi = modCombo;
	}
	return self;
}

-(void)setKeyCode:(NSInteger) keyCode{
	_keyCode = keyCode;
}

-(NSInteger)keyCode{
	return _keyCode;
}

-(void)setHotKeyId:(NSInteger)hotKeyId{
	_hotKeyId = hotKeyId;
}

-(NSInteger)hotKeyId{
	return _hotKeyId;
}

-(void)setModifierCombo:(NSUInteger)mCombo{
	_modifierCombi = mCombo;
}

-(NSUInteger)modifierCombo{
	return _modifierCombi;
}

-(void)setHotKeyRef:(EventHotKeyRef)eventRef{
	_eventHotKeyRef = eventRef;
}

-(EventHotKeyRef)hotKeyRef{
	return _eventHotKeyRef;
}

@end
