/*************************************************************************************************
*
*
*			MacZoop - "the framework for the rest of us"		 
*
*
*
*			ZExpParser.h			-- MacZoop expression parser
*
*
*
*			© 2000, Graham Cox
*
*
*
*
*************************************************************************************************/


#pragma once

#ifndef __ZEXPPARSER__
#define __ZEXPPARSER__

#define	__COCOA_IMPLEMENTATION__		1

#include <math.h>

#if defined(__MWERKS__)
#define bcopy BlockMoveData
#endif

// for MPW only (need to check for this here really):

#ifndef bcopy
#include	<string.h>
#define bcopy(src, dest, count) memcpy((dest), (src), (count))
#endif

#define	NUMBER		258
#define	FUNCTION	259
#define	VAR			260
#define	NEG			261


// other funcs:

#ifdef __cplusplus
extern "C" {
#endif

double_t	degtorad( double_t d );
double_t	radtodeg( double_t r );

// this structure used to form elements of a simple symbol table which can contain literal values or
// pointers to functions that return values

typedef struct symbol
{
	char* 	name;
	int		type;
	union
	{
		double_t	var;
		double_t	(*func)( double_t arg );
	}
	value;
	struct symbol*	next;
}
symbol;

// this structure used for a table of callable math functions

struct init
{
	char 		*fname;
	double_t 	(*fnct)( double_t arg );
};

int 		yyparse( void* param );
void		yyerror( char* errStr );

#ifdef __cplusplus
}
#endif


#ifndef __COCOA_IMPLEMENTATION__

// the parser class:

class	ZExpParser
{
private:
	symbol*		st;
	double_t	result;
	char*		expStr;
	
public:
	ZExpParser(){ Init(); }
	virtual ~ZExpParser();
	
	void				Init();

// the only methods you need (as a user!):

	virtual double_t	Evaluate( const char* expression );
	virtual void		SetSymbolValue( const char* aName, const double_t aValue );

// these called internally:

	symbol*				Get( const char* aName );
	symbol*				Put( const char* aName, const int aType );
	void				SetResult( const double_t v );
	char*				GetExpStr(){ return expStr; }				
};


#ifndef pi
#define pi 3.141592654
#endif

#endif

	
#endif