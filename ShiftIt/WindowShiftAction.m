/*
 ShiftIt: Resize windows with Hotkeys
 Copyright (C) 2010  Filip Krikava
 
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

#import "GCExpressionParser/GCMathParser.h"
#import "WindowShiftAction.h"
#import "ShiftIt.h"
#import "WindowManager.h"
#import "FMTDefines.h"


CGFloat evaluateExpression(NSString *expr, NSRect windowRect, NSSize screenSize);

@implementation WindowShiftAction

- (id) initWithExpressionsForX:(NSString *)exprX 
							 y:(NSString *)exprY 
						 width:(NSString *)exprWidth 
						height:(NSString *)exprHeight {
	if (![super init]) {
		return nil;
	}
	
	exprX_ = [exprX retain];
	exprY_ = [exprY retain];
	exprWidth_ = [exprWidth retain];
	exprHeight_ = [exprHeight retain];
	
	return self;
}

- (void) dealloc {
	[exprX_ release];
	[exprY_ release];
	[exprWidth_ release];
	[exprHeight_ release];
	
	[super dealloc];
}

- (BOOL) executeWithWindowManager:(WindowManager *)windowManager error:(NSError **)error {
	FMTAssertNotNil(windowManager);
	
	Window *focusedWindow = nil;
	NSError *localError = nil;
	
	GET_FOCUSED_WINDOW(focusedWindow, windowManager, error, localError);
	NSPoint origin;
	NSSize size;

	// just to shorten the code bellow:
	void *tmp[][3] = {
		{exprX_, &origin.x, @"Origin X"},
		{exprY_, &origin.y, @"Origin Y"},
		{exprWidth_, &size.width, @"Width"},
		{exprHeight_, &size.height, @"Height"}
	};
	
	for (int i=0; i<4; i++) {
		@try {
			*((CGFloat *)tmp[i][1]) = evaluateExpression(tmp[i][0], [focusedWindow frame], [[focusedWindow screen] size]);
			FMTDevLog(@"Expression: %@ (%@) evaluated to: %f", tmp[i][0], tmp[i][2], *((CGFloat *)tmp[i][1]));
		}
		@catch (NSException *e) {
			*error = CreateError(1, FMTStr(@"Invalid expression for: %@ (%@)", (NSString *)tmp[i][2], [e reason]), nil);
			return NO;
		}
	}
			
	[windowManager shiftWindow:focusedWindow origin:origin size:size error:&localError];
	HANDLE_WM_ERROR(error, localError);
	
	return YES;
}

+ (WindowShiftAction *)windowShiftActionFromExpressionForX:(NSString *)exprX 
														 y:(NSString *)exprY 
													 width:(NSString *)exprWidth 
													height:(NSString *)exprHeight
													 error:(NSError **)error {
	FMTAssertNotNil(exprX);
	FMTAssertNotNil(exprY);
	FMTAssertNotNil(exprWidth);
	FMTAssertNotNil(exprHeight);

	// TODO: check the expressions

	return [[WindowShiftAction alloc] initWithExpressionsForX:exprX y:exprY width:exprWidth height:exprHeight];
}

@end

inline CGFloat evaluateExpression(NSString *expr, NSRect windowRect, NSSize screenSize) {
	GCMathParser *parser = [GCMathParser parser];
	
	[parser setSymbolValue:windowRect.origin.x forKey:@"wx"];
	[parser setSymbolValue:windowRect.origin.y forKey:@"wy"];
	[parser setSymbolValue:windowRect.size.width forKey:@"ww"];
	[parser setSymbolValue:windowRect.size.height forKey:@"wh"];
	[parser setSymbolValue:screenSize.width forKey:@"sw"];
	[parser setSymbolValue:screenSize.height forKey:@"sh"];
	
	return (CGFloat)[parser evaluate:expr];	
}

