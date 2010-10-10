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

#import <ShortcutRecorder/SRCommon.h>

#import "FMTHotKeyManager.h"
#import "FMTDefines.h"

@interface FMTHotKey (Private)

- (NSInteger)carbonModifiers;

@end

@implementation FMTHotKey (Private) 

- (NSInteger) carbonModifiers {
	return SRCocoaToCarbonFlags([self modifiers]);
}

@end

@interface TWHotKeyRegistartion : NSObject
{
	FMTHotKey *hotKey_;
	SEL handler_;
	id provider_;
	id userData_;
	EventHotKeyRef ref_;
}

@property (readonly) FMTHotKey *hotKey;
@property (readonly) SEL handler;
@property (readonly) id provider;
@property (readonly) id userData;
@property (readonly) EventHotKeyRef ref;

- (id)initWithHotKey:(FMTHotKey *)hotKey handler:(SEL)handler provider:(id)provider userData:(id)userData ref:(EventHotKeyRef)ref;

@end

@implementation TWHotKeyRegistartion

@synthesize hotKey = hotKey_;
@synthesize handler = handler_;
@synthesize provider = provider_;
@synthesize userData = userData_;
@synthesize ref = ref_;

- (id)initWithHotKey:(FMTHotKey *)hotKey handler:(SEL)handler provider:(id)provider userData:(id)userData ref:(EventHotKeyRef)ref {
	if (![super init]) {
		return nil;
	}
	
	FMTAssertNotNil(hotKey);
	FMTAssertNotNil(handler);
	FMTAssertNotNil(provider);
	FMTAssertNotNil(ref);
	
	hotKey_ = [hotKey retain];
	handler_ = handler;
	provider_ = [provider retain];
	userData_ = [userData retain];
	ref_ = ref;
	
	return self;
}

- (void) dealloc {
	[hotKey_ release];
	[provider_ release];
	[userData_ release];
	
	[super dealloc];
}

@end

static NSMutableDictionary *allHotKeys;

OSStatus hotKeyHandler(EventHandlerCallRef inHandlerCallRef,EventRef inEvent,
					   void *userData)
{
	EventHotKeyID hotKeyID;
	GetEventParameter(inEvent,kEventParamDirectObject,typeEventHotKeyID,NULL,
					  sizeof(hotKeyID),NULL,&hotKeyID);
	
	NSNumber *id = [NSNumber numberWithInt:hotKeyID.id];
	
	TWHotKeyRegistartion* hotKeyReg = [allHotKeys objectForKey:id];
	
	if (hotKeyReg != nil) {
		objc_msgSend([hotKeyReg provider], [hotKeyReg handler], [hotKeyReg userData]);
		return noErr;
	} else {
		return eventNotHandledErr;
	}
}

@implementation FMTHotKeyManager

SINGLETON_BOILERPLATE(FMTHotKeyManager, sharedHotKeyManager);

- (id) init {
	if (![super init]) {
		return nil;
	}
	
	allHotKeys = [[NSMutableDictionary alloc] init];
	hotKeyIdSequence_ = 1;
	
	EventTypeSpec eventType;
	eventType.eventClass=kEventClassKeyboard;
	eventType.eventKind=kEventHotKeyPressed;
	
	InstallApplicationEventHandler(&hotKeyHandler, 1, &eventType, NULL, NULL);	
	
	return self;
}

- (void)dealloc {
	[allHotKeys release];
	
	[super dealloc];
}

// TODO: modify to propagate error
- (void)unregisterHotKey:(FMTHotKey *)hotKey {
	FMTAssertNotNil(hotKey);
	
	FMTDevLog(@"Unregistering hotKey %@", hotKey);
	
	// search for the registration
	TWHotKeyRegistartion *hotKeyReg;
	for (TWHotKeyRegistartion *e in [allHotKeys allValues]) {
		if ([hotKey isEqualTo:[e hotKey]]) {
			hotKeyReg = e;
			break;
		}
	}
	
	if (hotKeyReg) {
		UnregisterEventHotKey([hotKeyReg ref]);
	} else {
		// no registration found
		FMTDevLog(@"Unable to unregister hotKey: %@ - it has not been registered by this HotKeyManager", hotKey);
	}

}

- (void)registerHotKey:(FMTHotKey *)hotKey handler:(SEL)handler provider:(id)provider userData:(id)userData {

	FMTAssertNotNil(hotKey);
	FMTAssertNotNil(handler);
	FMTAssertNotNil(provider);
	
	FMTDevLog(@"Registering hotKey %@", hotKey);

	EventHotKeyID hotKeyID;
	// TODO: extract
	hotKeyID.signature = 'TFMT';
	// TODO: make sure it is thread safe
	hotKeyID.id = hotKeyIdSequence_++;
	
	EventHotKeyRef hotKeyRef;
	RegisterEventHotKey([hotKey keyCode], [hotKey carbonModifiers], hotKeyID,
						GetApplicationEventTarget(), 0, &hotKeyRef);
	
	if (!hotKeyRef) {
		NSLog(@"Unable to register hotKey: %@", hotKey);
		return;
	}
	
	// safe
	TWHotKeyRegistartion *hotKeyReg = [[TWHotKeyRegistartion alloc] initWithHotKey:hotKey 
																		   handler:handler 
																		  provider:provider
																		  userData:userData
																			   ref:hotKeyRef];
	
	[allHotKeys setObject:hotKeyReg forKey:[NSNumber numberWithInt:hotKeyID.id]];	
}

@end
