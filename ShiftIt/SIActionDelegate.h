//
//  Created by krikava on 14/12/11.
//
// To change the template use AppCode | Preferences | File Templates.
//

#import "SIWindowContext.h"

@protocol SIActionDelegate <NSObject>

@required
- (BOOL) execute:(id<SIWindowContext>)windowContext error:(NSError **)error;

@end