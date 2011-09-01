//
//  SimpleShiftItAction.h
//  ShiftIt
//
//  Created by Filip Krikava on 9/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AbstractShiftItAction.h"

typedef NSRect(^SimpleShiftItActionBlock)(NSRect, NSSize);

@interface SimpleShiftItAction : AbstractShiftItAction {
 @private
    SimpleShiftItActionBlock block_;
}

- (id) initWithIdentifier:(NSString *)identifier label:(NSString *)label uiTag:(NSInteger)uiTag block:(SimpleShiftItActionBlock)block;

@end
