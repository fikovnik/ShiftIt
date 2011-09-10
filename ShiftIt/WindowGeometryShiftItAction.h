//
//  SimpleShiftItAction.h
//  ShiftIt
//
//  Created by Filip Krikava on 9/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AbstractShiftItAction.h"

typedef NSRect(^SimpleWindowGeometryChangeBlock)(NSRect, NSSize);

@interface WindowGeometryShiftItAction : AbstractShiftItAction {
 @private
    SimpleWindowGeometryChangeBlock block_;
}

- (id) initWithIdentifier:(NSString *)identifier label:(NSString *)label uiTag:(NSInteger)uiTag block:(SimpleWindowGeometryChangeBlock)block;

@end
