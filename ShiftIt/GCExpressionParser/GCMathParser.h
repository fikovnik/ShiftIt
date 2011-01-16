//
//  GCMathParser.h
//  GCDrawKit
//
//  Created by graham on 28/08/2007.
//  Copyright 2007 Apptree.net. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ZExpParser.h"



@interface GCMathParser : NSObject
{
	symbol*			_st;			// symbol table; singly linked list
	NSString*		_expr;			// retained expression
	double			_result;		// the result of the evaluation
}


+ (double)			evaluate:(NSString*) expression;
+ (GCMathParser*)	parser;

- (double)			evaluate:(NSString*) expression;
- (NSString*)		expression;
- (const char*)		expressionCString;

- (void)			setSymbolValue:(double) value forKey:(NSString*) key;
- (double)			symbolValueForKey:(NSString*) key;

// private methods called internally:

- (symbol*)			getSymbol:(NSString*) key;
- (symbol*)			getSymbolForCString:(const char*) name;
- (symbol*)			initSymbol:(const char*) name ofType:(int) type;
- (void)			setResult:(double) result;


@end

// to simplify this even further for casual use (i.e. when you don't need variables), you can
// make use of this category on NSString:


@interface NSString (ExpressionParser)

- (double)			evaluateMath;

@end
