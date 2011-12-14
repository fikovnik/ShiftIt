//
//  WindowDriver.h
//  ShiftIt
//
//  Created by Filip Krikava on 9/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SIWindow.h"
#import "SIWindowInfo.h"

@protocol SIWindowDriver <NSObject>

@required
- (BOOL) findFocusedWindow:(id<SIWindow> *)window withInfo:(SIWindowInfo *)windowInfo error:(NSError **)error;

@end
