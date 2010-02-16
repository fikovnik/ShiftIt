//
//  SIHotKey.h
//  ShiftIt
//
//  Created by Aravindkumar Rajendiran on 10-02-14.
//  Copyright 2010 Grapewave. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Carbon/Carbon.h>

@interface SIHotKey : NSObject {
    NSInteger _keyCode;
	NSUInteger _modifierCombi;
	NSInteger _hotKeyId;
	
	EventHotKeyRef _eventHotKeyRef;
}
-(id)initWithIdentifier:(NSInteger)identifier keyCode:(NSInteger)keyCode modCombo:(NSUInteger)modCombo;

-(void)setHotKeyId:(NSInteger)hotKeyId;
-(NSInteger)hotKeyId;

-(void)setKeyCode:(NSInteger) keyCode;
-(NSInteger)keyCode;

-(void)setModifierCombo:(NSUInteger)mCombo;
-(NSUInteger)modifierCombo;

-(void)setHotKeyRef:(EventHotKeyRef)eventRef;
-(EventHotKeyRef)hotKeyRef;

@end
