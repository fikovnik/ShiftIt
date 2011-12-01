//
//  SimpleShiftItAction.h
//  ShiftIt
//
//  Created by Filip Krikava on 9/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ShiftIt.h"


@interface AbstractWindowGeometryShiftItAction : NSObject<ShiftItActionDelegate>

- (NSRect) shiftWindowRect:(NSRect)windowRect screenSize:(NSSize)screenSize withContext:(id<WindowContext>)windowContext;

@end

typedef NSRect(^SimpleWindowGeometryChangeBlock)(NSRect, NSSize);

@interface WindowGeometryShiftItAction : AbstractWindowGeometryShiftItAction {
 @private
    SimpleWindowGeometryChangeBlock block_;
}

- (id) initWithBlock:(SimpleWindowGeometryChangeBlock)block;

@end
