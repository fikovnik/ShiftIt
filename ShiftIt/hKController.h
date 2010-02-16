//
//  hKController.h
//  ShiftIt
//
//  Created by Aravindkumar Rajendiran on 10-02-14.
//  Copyright 2010 Grapewave. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SIHotKey.h"

@interface hKController : NSObject {

    NSMutableDictionary * _hotKeys;
}

+(id)getInstance;
-(BOOL)registerHotKey:(SIHotKey*)hotKey;
-(BOOL)unregisterHotKey:(SIHotKey*)hotKey;
-(BOOL)modifyHotKey:(SIHotKey*)hotKey;
@end
