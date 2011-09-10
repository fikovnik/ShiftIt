//
//  WindowDriver.h
//  ShiftIt
//
//  Created by Filip Krikava on 9/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WindowContext.h"

@protocol WindowDriver <NSObject>

@required
- (BOOL) getFocusedWindow:(id<SIWindow> *)window error:(NSError **)error;
- (BOOL) findFocusedWindow:(id<SIWindow> *)window ofPID:(NSInteger)pid error:(NSError **)error;

@end
