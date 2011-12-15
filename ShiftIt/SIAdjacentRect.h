//
//  Created by krikava on 01/12/11.
//
// To change the template use AppCode | Preferences | File Templates.
//

#import <Foundation/Foundation.h>
#import "SIDefines.h"
#import "FMT/FMT.h"

@interface SIRectWithValue : NSObject

@property(readonly) NSRect rect;
@property(readonly) id value;

- (id)initWithRect:(NSRect)rect value:(id)value;

+ (id)rect:(NSRect)rect withValue:(id)value;

@end

@interface SIRectDistance : NSObject

@property(readonly) CGFloat distance;
@property(readonly) NSRect rect;
@property(readonly) id value;

- (id)initWithDistance:(CGFloat)distance rect:(NSRect)rect value:(id)value;

@end

@interface SIAdjacentRect : NSObject

- (id)initWithRectValues:(NSArray *)rectValues;

- (NSArray *)rectsInDirection:(FMTDirection)direction fromRect:(NSRect)rect;

- (NSArray *)rectsInDirection:(FMTDirection)direction fromValue:(id)value;

- (NSArray *)buildDirectionalPath:(const FMTDirection *)directions fromValue:(id)value;

+ (id)adjacentRect:(NSArray *)rectValues;

@end