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


#import "SIHotKey.h"


@implementation SIHotKey

-(id)initWithIdentifier:(NSInteger)identifier keyCode:(NSInteger)keyCode modCombo:(NSNumber*)modCombo{
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

-(void)setModifierCombo:(NSNumber*)mCombo{
	_modifierCombi = mCombo;
}

-(NSNumber*)modifierCombo{
	return _modifierCombi;
}

-(void)setHotKeyRef:(EventHotKeyRef)eventRef{
	_eventHotKeyRef = eventRef;
}

-(EventHotKeyRef)hotKeyRef{
	return _eventHotKeyRef;
}

@end
