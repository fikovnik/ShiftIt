/*
 Copyright (c) 2010 Filip Krikava
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 */

#import "FMTHotKey.h"
#import "FMTDefines.h"

@implementation FMTHotKey

@synthesize keyCode = keyCode_;
@synthesize modifiers = modifiers_;

- (id)initWithKeyCode:(NSInteger)keyCode modifiers:(NSUInteger)modifiers {
	
	if (![super init]) {
		return nil;
	}

	keyCode_ = keyCode;
	
	// TODO: assert that the code and modifiers make sense	
	modifiers_ = modifiers;
	
	return self;
}

- (NSString *)description {
	return FMTStr(@"code: %d modifiers: %@ (%ld)", keyCode_, FMTStringForCocoaModifiers(modifiers_), modifiers_);
}

- (BOOL)isEqualTo:(id)object {

	if ([object isKindOfClass:[self class]] == NO) {
		return NO;
	}
	
	FMTHotKey *other = (FMTHotKey *) object;
	return (keyCode_ == [other keyCode]
			&& modifiers_ == [other modifiers]);
}

// TODO: add hash

@end

#pragma mark Key code and modifiers conversion methods

// this method is based on the SRStringForCocoaModifierFlags from SRCommon.m
// in the ShortcutRecorder. The reason why it is duplicated here is to not to
// have the dependency on ShortcutRecorder in FMTHotKey
NSString *FMTStringForCocoaModifiers(NSUInteger modifiers) {
    NSString *modifiersString = [NSString stringWithFormat:@"%@%@%@%@",
								 (modifiers & NSControlKeyMask ? [NSString stringWithFormat:@"%C", kControlUnicode] : @""),
								 (modifiers & NSAlternateKeyMask ? [NSString stringWithFormat:@"%C", kOptionUnicode] : @""),
								 (modifiers & NSShiftKeyMask ? [NSString stringWithFormat:@"%C", kShiftUnicode] : @""),
								 (modifiers & NSCommandKeyMask ? [NSString stringWithFormat:@"%C", kCommandUnicode] : @"")];
	
	return modifiersString;
}