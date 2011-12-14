//
//  Created by krikava on 01/12/11.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>
#import "SIDefines.h"

@interface SIAdjacentRect : NSObject {
  @private
    NSDictionary *rectangles_;
}

- (id)initWithRect:(NSArray *)rectangles forValues:(NSArray *)values;
- (NSArray *) rectsInDirection:(SIDirection)direction;

+ (id)adjacentRect:(NSArray *)rectangles forValues:(NSArray *)values;

@end