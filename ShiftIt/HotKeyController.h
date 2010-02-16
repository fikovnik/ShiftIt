//
//  HotKeyController.h
//  ShiftIt
//
//  Created by Aravindkumar Rajendiran on 10-02-13.
//  Copyright 2010 Aravindkumar. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SIHotKey.h"

@interface HotKeyController : NSObject {
    NSMutableDictionary * _hotKeys;
}

+(id)getInstance;
-(BOOL)registerHotKey:(SIHotKey*)hotKey;
-(BOOL)unregisterHotKey:(SIHotKey*)hotKey;
-(BOOL)modifyHotKey:(SIHotKey*)hotKey;
@end
