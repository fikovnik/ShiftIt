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

-(id)initWithIdentifier:(NSInteger)identifier keyCode:(NSInteger)keyCode modCombo:(NSInteger)modCombo{
	if(self ==[super init]){
		hotKeyId_ = identifier;
		keyCode_ = keyCode;
		modifierCombi_ = modCombo;
	}
	return self;
}

-(void)setKeyCode:(NSInteger) keyCode{
	keyCode_ = keyCode;
}

-(NSInteger)keyCode{
	return keyCode_;
}

-(void)setHotKeyId:(NSInteger)hotKeyId{
	hotKeyId_ = hotKeyId;
}

-(NSInteger)hotKeyId{
	return hotKeyId_;
}

-(void)setModifierCombo:(NSInteger)mCombo{
	modifierCombi_ = mCombo;
}

-(NSInteger)modifierCombo{
	return modifierCombi_;
}

-(void)setHotKeyRef:(EventHotKeyRef)eventRef{
	eventHotKeyRef_ = eventRef;
}

-(EventHotKeyRef)hotKeyRef{
	return eventHotKeyRef_;
}

@end
