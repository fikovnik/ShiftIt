/*
 ShiftIt: Window Organizer for OSX
 Copyright (c) 2010-2011 Filip Krikava

 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/>.

 */

#import "SIScreen.h"
#import "SIDefines.h"
#import "SIAdjacentRectangles.h"

const FMTDirection kDefaultDirections[] = {kRightDirection, kBottomDirection, kLeftDirection, kTopDirection};


@interface NSScreen (Extras)

+ (NSScreen *)primaryScreen;
- (BOOL)isPrimary;
- (BOOL)isBelowPrimary;
- (NSRect)screenFrame;
- (NSRect)screenVisibleFrame;

@end

@implementation NSScreen (Extras)

+ (NSScreen *)primaryScreen {
	return [[NSScreen screens] objectAtIndex:0];
}

- (BOOL)isPrimary {
	return self == [NSScreen primaryScreen];
}

- (BOOL)isBelowPrimary {
	BOOL isBellow = NO;
	for (NSScreen *s in [NSScreen screens]) {
		NSRect r = [s frame];
		COCOA_TO_SCREEN_COORDINATES(r);
		if (r.origin.y > 0) {
			isBellow = YES;
			break;
		}
	}
	return isBellow;
}

- (NSRect)screenFrame {
    NSRect r = [self frame];
    COCOA_TO_SCREEN_COORDINATES(r);
    return  r;
}

- (NSRect)screenVisibleFrame {
    NSRect r = [self visibleFrame];
    COCOA_TO_SCREEN_COORDINATES(r);
    return  r;
}

@end

@interface SIScreen ()
@property(readonly) NSScreen *screen;

+ (SIScreen *)screenRelativeTo_:(SIScreen *)screen withOffset:(NSInteger)offset;
@end

@implementation SIScreen {
@private
    NSScreen *screen_;
}

@synthesize screen = screen_;
@dynamic size;
@dynamic primary;
@dynamic rect;
@dynamic visibleRect;

- (id) initWithNSScreen:(NSScreen *)screen {
	FMTAssertNotNil(screen);

	if (![super init]) {
		return nil;
	}

    screen_ = [screen retain];

	return self;
}

- (BOOL) primary {
    return [screen_ isPrimary];
}

- (NSRect) rect {
	// screen coordinates of the best fit window
	NSRect r = [screen_ screenFrame];

    return r;
}

- (NSRect) visibleRect {
	// visible screen coordinates of the best fit window
	// the visible screen denotes some inner rect of the screen frame
	// which is visible - not occupied by menu bar or dock
	NSRect r = [screen_ screenVisibleFrame];

    return r;
}

- (NSSize) size {
	return [self visibleRect].size;
}

- (NSString *) description {
    NSDictionary *info = [screen_ deviceDescription];

    return FMTStr(@"id=%@, primary=%d, rect=(%@) visibleRect=(%@)", [info objectForKey: @"NSScreenNumber"], [self primary], RECT_STR([self rect]), RECT_STR([self visibleRect]));
}

- (BOOL)isEqual:(id)object {
    if (object == self)
           return YES;
       if (!object || ![object isKindOfClass:[self class]])
           return NO;
       return [self isEqualToScreen:(SIScreen *)object];
}

- (BOOL)isEqualToScreen:(SIScreen *)screen {
    return [screen_ isEqual:[screen screen]];
}

- (NSUInteger)hash {
    return [screen_ hash];
}

+ (NSArray *) screens {
    return [[NSScreen screens] map:^id(id item) {
        return [SIScreen screenFromNSScreen:item];
    }];
}

+ (SIScreen *) primaryScreen {
    return [SIScreen screenFromNSScreen:[NSScreen primaryScreen]];
}

+ (SIScreen *) screenFromNSScreen:(NSScreen *)screen {
    return [[[SIScreen alloc] initWithNSScreen:screen] autorelease];
}

/**
 * Chooses the best screen for the given window rect (screen coord).
 *
 * For each screen it computes the intersecting rectangle and its size.
 * The biggest is the screen where is the most of the window hence the best fit.
 */
+ (SIScreen *) screenForWindowGeometry:(NSRect)geometry {
	NSScreen *fitScreen = [NSScreen mainScreen];
	double maxSize = 0;

	for (NSScreen *screen in [NSScreen screens]) {
		NSRect screenRect = [screen frame];
		// need to convert coordinates
		COCOA_TO_SCREEN_COORDINATES(screenRect);

		NSRect intersectRect = NSIntersectionRect(screenRect, geometry);

		if (intersectRect.size.width > 0 ) {
			double size = intersectRect.size.width * intersectRect.size.height;
			if (size > maxSize) {
				fitScreen = screen;
				maxSize = size;
			}
		}
	}

	return [SIScreen screenFromNSScreen:fitScreen];
}

- (SIScreen *)previousScreen {
    return [SIScreen screenRelativeTo_:self withOffset:-1];
}

- (SIScreen *)nextScreen {
    return [SIScreen screenRelativeTo_:self withOffset:1];
}

+ (SIScreen *)screenRelativeTo_:(SIScreen *)screen withOffset:(NSInteger)offset {
    NSArray *screens = [SIScreen screens];
    if ([screens count] < 2) {
        return screen;
    }

    NSArray *rects = [screens map:^id(id item) {
        return [SIValueRect rect:[item rect] withValue:item];
    }];

    // build the adjacent rectangles
    SIAdjacentRectangles *adjr = [SIAdjacentRectangles adjacentRect:rects];

    // find the path, it will be always the same unless screens change hence we compute it again (it's cheap)
    // seems maybe a bit of an overkill considering that ppl might not usually have more than 2 screens :)
    NSArray *path = [adjr buildDirectionalPath:kDefaultDirections fromValue:[SIScreen primaryScreen]];
    NSUInteger idx = [path indexWhere:^BOOL(id item) {
        return [screen isEqualToScreen:item];
    }];

    // count the offset
    NSUInteger count = [path count];
    if (offset < 0) {
        offset = count - -offset % count;
    }

    idx += offset;

    // so we wrap over
    idx %= count;

    return [path objectAtIndex:idx];
}

- (void)dealloc {
    [screen_ release];

    [super dealloc];
}

@end
