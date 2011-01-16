/*************************************************************************************************
*
*
*			MacZoop - "the framework for the rest of us"		 
*
*
*
*			ZExpParser.cpp			-- MacZoop expression parser
*
*
*
*			� 2000, Graham Cox
*
*
*
*
*************************************************************************************************/



#include	"ZExpParser.h"
#ifdef __COCOA_IMPLEMENTATION__
#include "GCMathParser.h"
#endif

#include 	<stdlib.h>
#include 	<string.h>
#include	<ctype.h>

#ifndef __MRC__
#include	<alloca.h>
#endif


double_t	degtorad( double_t d )
{
	return pi * ( d / 180.0 );
}



double_t	radtodeg( double_t r )
{
	return 180.0 * ( r / pi );
}


#define		YYDEBUG			0
#define 	YYPARSE_PARAM 	param

#ifdef __COCOA_IMPLEMENTATION__
#define 	YYLEX_PARAM 	(GCMathParser*) param
#else
#define 	YYLEX_PARAM 	(ZExpParser*) param
#endif

typedef union
{
	double_t 	val;
	symbol		*fptr;
}
YYSTYPE;

#ifndef YYLTYPE
typedef
  struct yyltype
    {
      int timestamp;
      int first_line;
      int first_column;
      int last_line;
      int last_column;
      char *text;
   }
  yyltype;

#define YYLTYPE yyltype
#endif

#ifndef YYDEBUG
#define YYDEBUG 1
#endif

#include <stdio.h>

#ifndef __STDC__
#define const
#endif



#define	YYFINAL		33
#define	YYFLAG		-32768
#define	YYNTBASE	18

#define YYTRANSLATE(x) ((unsigned)(x) <= 261 ? yytranslate[x] : 20)

static const char yytranslate[] = {     0,
     2,     2,     2,     2,     2,     2,     2,     2,     2,    15,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     2,    14,     2,     2,    16,
    17,     9,     8,     2,     7,     2,    10,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,     2,    12,     2,
     6,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,     2,    13,     2,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     1,     2,     3,     4,     5,
    11
};

static const short yyrline[] = {     0,
    74,    75,    76,    79,    80,    81,    82,    83,    84,    85,
    86,    87,    88,    89,    90
};

static const char * const yytname[] = {     0,
"error","$illegal.","NUMBER","FUNCTION","VAR","'='","'-'","'+'","'*'","'/'",
"NEG","';'","'^'","'%'","'\\n'","'('","')'","line"
};

static const short yyr1[] = {     0,
    18,    18,    18,    19,    19,    19,    19,    19,    19,    19,
    19,    19,    19,    19,    19
};

static const short yyr2[] = {     0,
     1,     2,     2,     1,     4,     1,     3,     3,     3,     3,
     3,     2,     3,     3,     3
};

static const short yydefact[] = {     0,
     0,     4,     0,     6,     0,     1,     0,     0,     3,     0,
     0,    12,     0,     0,     0,     0,     0,     0,     0,     2,
     0,     7,    15,     9,     8,    10,    11,    13,    14,     5,
     0,     0,     0
};

static const short yydefgoto[] = {    31,
     8
};

static const short yypact[] = {    -1,
   -14,-32768,   -11,    25,    19,-32768,    19,    42,-32768,    19,
    19,    -3,    20,    19,    19,    19,    19,    19,    19,-32768,
    31,    51,-32768,    33,    33,    -3,    -3,    -3,    -3,-32768,
     8,    32,-32768
};

static const short yypgoto[] = {-32768,
     2
};


#define	YYLAST		65


static const short yytable[] = {     1,
     9,     2,     3,     4,    10,     5,    12,    32,    13,    18,
    19,    21,    22,     6,     7,    24,    25,    26,    27,    28,
    29,     2,     3,     4,     0,     5,    14,    15,    16,    17,
    11,    33,    18,    19,     7,     0,    23,    14,    15,    16,
    17,    16,    17,    18,    19,    18,    19,    30,    14,    15,
    16,    17,     0,     0,    18,    19,    20,    14,    15,    16,
    17,     0,     0,    18,    19
};

static const short yycheck[] = {     1,
    15,     3,     4,     5,    16,     7,     5,     0,     7,    13,
    14,    10,    11,    15,    16,    14,    15,    16,    17,    18,
    19,     3,     4,     5,    -1,     7,     7,     8,     9,    10,
     6,     0,    13,    14,    16,    -1,    17,     7,     8,     9,
    10,     9,    10,    13,    14,    13,    14,    17,     7,     8,
     9,    10,    -1,    -1,    13,    14,    15,     7,     8,     9,
    10,    -1,    -1,    13,    14
};
#define YYIMPURE 1

/* -*-C-*-  Note some compilers choke on comments on `#line' lines.  */


/* Skeleton output parser for bison,
   Copyright (C) 1984 Bob Corbett and Richard Stallman

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 1, or (at your option)
   any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
   
   Modified for use with Metrowerks CodeWarrior for Mac/Power Mac
   Portions Copyright (C) 1995 Dan Wright							  */


#if (!defined (__STDC__) && defined (sparc)) || defined (__sparc__) || (defined(__MWERKS__) && defined(powerc))
#include <alloca.h>
#endif

/* This is the parser code that is written into each bison parser
  when the %semantic_parser declaration is not specified in the grammar.
  It was written by Richard Stallman by simplifying the hairy parser
  used when %semantic_parser is specified.  */

/* Note: there must be only one dollar sign in this file.
   It is replaced by the list of actions, each action
   as one case of the switch.  */

#define yyerrok		(yyerrstatus = 0)
#define yyclearin	(yychar = YYEMPTY)
#define YYEMPTY		-2
#define YYEOF		0
#define YYFAIL		goto yyerrlab;
#define YYACCEPT	return(0)
#define YYABORT 	return(1)
#define YYERROR		goto yyerrlab

#define YYTERROR	1
#define YYERRCODE	256

#ifndef YYIMPURE
#define YYLEX		yylex()
#endif

#ifndef YYPURE
#define YYLEX		yylex(&yylval, &yylloc, YYLEX_PARAM )
#endif

/* If nonreentrant, generate the variables here */

#ifndef YYIMPURE

int	yychar;			/*  the lookahead symbol		*/
YYSTYPE	yylval;			/*  the semantic value of the		*/
				/*  lookahead symbol			*/

YYLTYPE yylloc;			/*  location data for the lookahead	*/
				/*  symbol				*/

int yynerrs;			/*  number of parse errors so far       */
#endif  /* YYIMPURE */

static int		yylex( YYSTYPE* lvalp, YYLTYPE* llocp, void* param );

#if YYDEBUG != 0
int yydebug;			/*  nonzero means print parse trace	*/
/* Since this is uninitialized, it does not stop multiple parsers
   from coexisting.  */
#endif

/*  YYMAXDEPTH indicates the initial size of the parser's stacks	*/

#ifndef	YYMAXDEPTH
#define YYMAXDEPTH 200
#endif

/*  YYMAXLIMIT is the maximum size the stacks can grow to
    (effective only if the built-in stack extension method is used).  */

#ifndef YYMAXLIMIT
#define YYMAXLIMIT 10000
#endif



int yyparse( void* param )
{
	register int yystate;
	register int yyn;
	register short *yyssp;
	register YYSTYPE *yyvsp;
	YYLTYPE *yylsp;
	int yyerrstatus;	/*  number of tokens to shift before error messages enabled */
	int yychar1;		/*  lookahead token as an internal (translated) token number */
	
	short	yyssa[YYMAXDEPTH];	/*  the state stack			*/
	YYSTYPE yyvsa[YYMAXDEPTH];	/*  the semantic value stack		*/
	YYLTYPE yylsa[YYMAXDEPTH];	/*  the location stack			*/
	
	short *yyss = yyssa;		/*  refer to the stacks thru separate pointers */
	YYSTYPE *yyvs = yyvsa;	/*  to allow yyoverflow to reallocate them elsewhere */
	YYLTYPE *yyls = yylsa;
	
	int yymaxdepth = YYMAXDEPTH;
	
#ifndef YYPURE
	int yychar;
	YYSTYPE yylval;
	YYLTYPE yylloc;
	int yynerrs;
#endif
	
	YYSTYPE yyval;		/*  the variable used to return		*/
						/*  semantic values from the action	*/
						/*  routines				*/
	int yylen;
	
#if YYDEBUG != 0
	if (yydebug)
		fprintf(stderr, "Starting parse\n");
#endif
	
	yystate = 0;
	yyerrstatus = 0;
	yynerrs = 0;
	yychar = YYEMPTY;		/* Cause a token to be read.  */
	
	/* Initialize stack pointers.
	 Waste one element of value and location stack
	 so that they stay on the same level as the state stack.  */
	
	yyssp = yyss - 1;
	yyvsp = yyvs;
	yylsp = yyls;
	
	/* Push a new state, which is found in  yystate  .  */
	/* In all cases, when you get here, the value and location stacks
	have just been pushed. so pushing a state here evens the stacks.  */
yynewstate:
	
	*++yyssp = yystate;
	
	if (yyssp >= yyss + yymaxdepth - 1)
		{
	/* Give user a chance to reallocate the stack */
	/* Use copies of these so that the &'s don't force the real ones into memory. */
		YYSTYPE *yyvs1 = yyvs;
		short *yyss1 = yyss;
		
		  /* Get the current used size of the three stacks, in elements.  */
		int size = yyssp - yyss + 1;
		
#ifdef yyoverflow
		YYLTYPE *yyls1 = yyls;
		  /* Each stack pointer address is followed by the size of
		 the data in use in that stack, in bytes.  */
		yyoverflow("parser stack overflow",
			 &yyss1, size * sizeof (*yyssp),
			 &yyvs1, size * sizeof (*yyvsp),
			 &yyls1, size * sizeof (*yylsp),
			 &yymaxdepth);
		
		yyss = yyss1; yyvs = yyvs1; yyls = yyls1;
#else /* no yyoverflow */
		  /* Extend the stack our own way.  */
		if (yymaxdepth >= YYMAXLIMIT)
			yyerror("parser stack overflow");
		yymaxdepth *= 2;
		if (yymaxdepth > YYMAXLIMIT)
			yymaxdepth = YYMAXLIMIT;
		yyss = (short *) alloca (yymaxdepth * sizeof (*yyssp));
		bcopy ((char *)yyss1, (char *)yyss, size * sizeof (*yyssp));
		yyvs = (YYSTYPE *) alloca (yymaxdepth * sizeof (*yyvsp));
		bcopy ((char *)yyvs1, (char *)yyvs, size * sizeof (*yyvsp));
#ifdef YYLSP_NEEDED
		yyls = (YYLTYPE *) alloca (yymaxdepth * sizeof (*yylsp));
		bcopy ((char *)yyls1, (char *)yyls, size * sizeof (*yylsp));
#endif
#endif /* no yyoverflow */
		
		yyssp = yyss + size - 1;
		yyvsp = yyvs + size - 1;
#ifdef YYLSP_NEEDED
		yylsp = yyls + size - 1;
#endif
		
#if YYDEBUG != 0
		if (yydebug)
			fprintf(stderr, "Stack size increased to %d\n", yymaxdepth);
#endif
		
		if (yyssp >= yyss + yymaxdepth - 1)
			YYABORT;
		}
	
#if YYDEBUG != 0
	if (yydebug)
		fprintf(stderr, "Entering state %d\n", yystate);
#endif
	
	/* Do appropriate processing given the current state.  */
	/* Read a lookahead token if we need one and don't already have one.  */
yyresume:
	
	/* First try to decide what to do without reference to lookahead token.  */
	
	yyn = yypact[yystate];
	if (yyn == YYFLAG)
		goto yydefault;
	
	/* Not known => get a lookahead token if don't already have one.  */
	
	/* yychar is either YYEMPTY or YYEOF
	 or a valid token in external form.  */
	
	if (yychar == YYEMPTY)
		{
#if YYDEBUG != 0
		if (yydebug)
			fprintf(stderr, "Reading a token: ");
#endif
		yychar = YYLEX;
		}
	
	/* Convert token to internal form (in yychar1) for indexing tables with */
	
	if (yychar <= 0)		/* This means end of input. */
		{
		yychar1 = 0;
		yychar = YYEOF;		/* Don't call YYLEX any more */
		
#if YYDEBUG != 0
		if (yydebug)
			fprintf(stderr, "Now at end of input.\n");
#endif
		}
	else
		{
		yychar1 = YYTRANSLATE(yychar);
		
#if YYDEBUG != 0
		if (yydebug)
			fprintf(stderr, "Next token is %d (%s)\n", yychar, yytname[yychar1]);
#endif
		}
	
	yyn += yychar1;
	if (yyn < 0 || yyn > YYLAST || yycheck[yyn] != yychar1)
		goto yydefault;
	
	yyn = yytable[yyn];
	
	/* yyn is what to do for this token type in this state.
	 Negative => reduce, -yyn is rule number.
	 Positive => shift, yyn is new state.
	   New state is final state => don't bother to shift,
	   just return success.
	 0, or most negative number => error.  */
	
	if (yyn < 0)
		{
		if (yyn == YYFLAG)
			goto yyerrlab;
		yyn = -yyn;
		goto yyreduce;
		}
	else if (yyn == 0)
		goto yyerrlab;
	
	if (yyn == YYFINAL)
		YYACCEPT;
	
	/* Shift the lookahead token.  */
	
#if YYDEBUG != 0
	if (yydebug)
		fprintf(stderr, "Shifting token %d (%s), ", yychar, yytname[yychar1]);
#endif
	
	/* Discard the token being shifted unless it is eof.  */
	if (yychar != YYEOF)
		yychar = YYEMPTY;
	
	*++yyvsp = yylval;
#ifdef YYLSP_NEEDED
	*++yylsp = yylloc;
#endif
	
	/* count tokens shifted since error; after three, turn off error status.  */
	if (yyerrstatus)
		yyerrstatus--;
	
	yystate = yyn;
	goto yynewstate;
	
	/* Do the default action for the current state.  */
yydefault:
	
	yyn = yydefact[yystate];
	if (yyn == 0)
		goto yyerrlab;
	
	/* Do a reduction.  yyn is the number of a rule to reduce with.  */
yyreduce:
	yylen = yyr2[yyn];
	yyval = yyvsp[1-yylen]; /* implement default value of the action */
	
#if YYDEBUG != 0
	if (yydebug)
		{
		if (yylen == 1)
			fprintf (stderr, "Reducing 1 value via line %d, ", yyrline[yyn]);
		else
			fprintf (stderr, "Reducing %d values via line %d, ", yylen, yyrline[yyn]);
		}
#endif
	

  switch (yyn) {

case 2:
{
	#ifdef __COCOA_IMPLEMENTATION__
	[(GCMathParser*)param setResult:yyvsp[-1].val];
	#else
	((ZExpParser*) param )->SetResult( yyvsp[-1].val );
	#endif
    break;
}
case 3:
{ yyerrok; ;
    break;}
case 4:
{ yyval.val = yyvsp[0].val ;
    break;}
case 5:
{ yyval.val = (*(yyvsp[-3].fptr->value.func))( yyvsp[-1].val )	;
    break;}
case 6:
{ yyval.val = yyvsp[0].fptr->value.var ;
    break;}
case 7:
{ yyval.val = yyvsp[0].val; yyvsp[-2].fptr->value.var = yyvsp[0].val ;
    break;}
case 8:
{ yyval.val = yyvsp[-2].val + yyvsp[0].val ;
    break;}
case 9:
{ yyval.val = yyvsp[-2].val - yyvsp[0].val ;
    break;}
case 10:
{ yyval.val = yyvsp[-2].val * yyvsp[0].val ;
    break;}
case 11:
{ yyval.val = yyvsp[-2].val / yyvsp[0].val ;
    break;}
case 12:
{ yyval.val = -yyvsp[0].val ;
    break;}
case 13:
{ yyval.val = pow( yyvsp[-2].val, yyvsp[0].val ) ;
    break;}
case 14:
{ yyval.val = fmod( yyvsp[-2].val, yyvsp[0].val ) ;
    break;}
case 15:
{ yyval.val = yyvsp[-1].val ;
    break;}
}
   /* the action file gets copied in in place of this dollarsign */

	
	yyvsp -= yylen;
	yyssp -= yylen;
#ifdef YYLSP_NEEDED
	yylsp -= yylen;
#endif
	
#if YYDEBUG != 0
	if (yydebug)
		{
		short *ssp1 = yyss - 1;
		fprintf (stderr, "state stack now");
		while (ssp1 != yyssp)
			fprintf (stderr, " %d", *++ssp1);
		fprintf (stderr, "\n");
		}
#endif
	
	*++yyvsp = yyval;
	
#ifdef YYLSP_NEEDED
	yylsp++;
	if (yylen == 0)
		{
		yylsp->first_line = yylloc.first_line;
		yylsp->first_column = yylloc.first_column;
		yylsp->last_line = (yylsp-1)->last_line;
		yylsp->last_column = (yylsp-1)->last_column;
		yylsp->text = 0;
		}
	else
		{
		yylsp->last_line = (yylsp+yylen-1)->last_line;
		yylsp->last_column = (yylsp+yylen-1)->last_column;
		}
#endif
	
	/* Now "shift" the result of the reduction.
	 Determine what state that goes to,
	 based on the state we popped back to
	 and the rule number reduced by.  */
	
	yyn = yyr1[yyn];
	
	yystate = yypgoto[yyn - YYNTBASE] + *yyssp;
	if (yystate >= 0 && yystate <= YYLAST && yycheck[yystate] == *yyssp)
		yystate = yytable[yystate];
	else
		yystate = yydefgoto[yyn - YYNTBASE];
	
	goto yynewstate;
	
yyerrlab:   /* here on detecting error */
	
	if (! yyerrstatus)
	/* If not already recovering from an error, report this error.  */
		{
		++yynerrs;
		yyerror("parse error");
		}
	
	if (yyerrstatus == 3)
		{
		/* if just tried and failed to reuse lookahead token after an error, discard it.  */
		
		/* return failure if at end of input */
		if (yychar == YYEOF)
			YYABORT;
		
#if YYDEBUG != 0
		if (yydebug)
			fprintf(stderr, "Discarding token %d (%s).\n", yychar, yytname[yychar1]);
#endif
		
		yychar = YYEMPTY;
		}
	
	/* Else will try to reuse lookahead token
	 after shifting the error token.  */
	
	yyerrstatus = 3;		/* Each real token shifted decrements this */
	
	goto yyerrhandle;
	
yyerrdefault:  /* current state does not do anything special for the error token. */
	
	
yyerrpop:   /* pop the current state because it cannot handle the error token */
	
	if (yyssp == yyss)
		YYABORT;
	yyvsp--;
	yystate = *--yyssp;
#ifdef YYLSP_NEEDED
	yylsp--;
#endif
	
#if YYDEBUG != 0
	if (yydebug)
		{
		short *ssp1 = yyss - 1;
		fprintf (stderr, "Error: state stack now");
		while (ssp1 != yyssp)
			fprintf (stderr, " %d", *++ssp1);
		fprintf (stderr, "\n");
		}
#endif
	
	yyerrhandle:
	
	yyn = yypact[yystate];
	if (yyn == YYFLAG)
		goto yyerrdefault;
	
	yyn += YYTERROR;
	if (yyn < 0 || yyn > YYLAST || yycheck[yyn] != YYTERROR)
		goto yyerrdefault;
	
	yyn = yytable[yyn];
	if (yyn < 0)
		{
		if (yyn == YYFLAG)
			goto yyerrpop;
		yyn = -yyn;
		goto yyreduce;
		}
	else if (yyn == 0)
		goto yyerrpop;
	
	if (yyn == YYFINAL)
		YYACCEPT;
	
#if YYDEBUG != 0
	if (yydebug)
		fprintf(stderr, "Shifting error token, ");
#endif
	
	*++yyvsp = yylval;
#ifdef YYLSP_NEEDED
	*++yylsp = yylloc;
#endif
	
	yystate = yyn;
	goto yynewstate;
}


/* static C code */

#pragma mark -


// scanner function, called by yyparse to fetch tokens:

static int	yylex( YYSTYPE* lvalp, YYLTYPE* llocp, void* param )
{
	// <param> is the reference to the parser object.
	
	static   char*	wptr = NULL;
	static   int	length = 0;
	static 	 char*	sbuf = NULL;
	static 	 bool	pFlag = false;
	
	register char	c;
	int				i;
	
	// if wptr is NULL, we have nothing to parse, so fetch the string from the
	// parser object
	
	if ( wptr == NULL )
	#ifdef __COCOA_IMPLEMENTATION__
		wptr = (char*)[(GCMathParser*)param expressionCString];
	#else
		wptr = (char*)(((ZExpParser*)param)->GetExpStr());
	#endif
	// this flag set if we finished parsing and have just to clean up
		
	if ( pFlag )
	{
		// we handled the whole string, so reset everything and return 0.
	
		pFlag = false;
		wptr = NULL;
		return 0;
	}
		
	// scan until we find something that isn't whitespace:
	
	while((( c = *wptr++ ) == ' ' ) || ( c == '\t' )){};
	
	// if end of string, return <newline> which causes ultimate production. We do not
	// return 0 yet, because we still have to clean up our static variables.
	
	if ( c == 0 )
	{
		pFlag = true;
		return '\n';
	}
		
	// if character is a number or part of a number, return the number:
	
	if ( c == '.' || isdigit( c ))
	{
		lvalp->val = strtod( --wptr, &wptr );
		return NUMBER;
	}
	
	// if character starts an identifier (variable or function name), then
	// we use the symbol table to resolve the token
	
	if ( isalpha( c ))
	{
		symbol*		s;
		
		// make buffer long enough for 40-character symbol initially
		
		if ( length == 0 )
		{
			length = 40;
			sbuf = (char*) malloc( length + 1 );
		}
		
		i = 0;
		do
		{
			// buffer full, enlarge it...
			
			if ( i == length )
			{
				length *= 2;
				sbuf = (char*) realloc( sbuf, length + 1 );
			}
			
			// add char to buffer & get the next one
			
			sbuf[i++] = c;
			c = *wptr++;
		}
		while( c != '\0' && (isalnum( c )));
		
		// push back last character
		
		--wptr;
		sbuf[i] = 0;
		
		// add to or query the symbol table:
		
#ifdef __COCOA_IMPLEMENTATION__
		s = [(GCMathParser*)param getSymbolForCString:sbuf];
		
		if ( s == NULL )
			s = [(GCMathParser*)param initSymbol:sbuf ofType:VAR];

#else
		s = (ZExpParser*)param->Get( sbuf );
		
		if ( s == NULL )
		{
			// a new variable, so set up the table with it
			
			s = (ZExpParser*)param->Put( sbuf, VAR );
		}
#endif
		
		lvalp->fptr = s;
		return s->type;
	}
	
	// all other characters are tokens in themselves:
	
	return c;
}


// error function

void yyerror ( char* errStr )
{
	//FailOSErr( kExpParseErr );
	
#ifdef __COCOA_IMPLEMENTATION__
	[NSException raise:@"Error in expression" format:@"%s", errStr];
#endif	
}



#pragma mark -

#ifndef __COCOA_IMPLEMENTATION__
// table to initialise symbol table for built-in function calls

static struct init gMathFunctions[]=
{
     "sin", 	sin,
     "cos", 	cos,
     "tan", 	tan,
     "log", 	log10,
     "log2",	log2,
     "ln",		log,
     "exp", 	exp,
     "abs",		fabs,
     "sqrt", 	sqrt,
     "asin", 	asin,
     "acos", 	acos,
     "atan", 	atan,
     "sinh", 	sinh,
     "cosh", 	cosh,
     "tanh", 	tanh,
     "asinh",	asinh,
     "acosh",	acosh,
     "atanh",	atanh,
     "ceil",	ceil,
     "floor",	floor,
     "round", 	round,
     "trunc", 	trunc,
     "rint", 	rint,
     "near",	nearbyint,
     "dtor",	degtorad,
     "rtod",	radtodeg,
     0, 		0
};

// class methods:

/*---------------------------------***  DESTRUCTOR  ***---------------------------------*/


ZExpParser::~ZExpParser()
{
	// free symbol table
	
	symbol	*ns, *s;
	
	s = st;
	
	while( s )
	{
		ns = s->next;
		free( s->name );
		free( s );
		s = ns;
	}
	
	st = NULL;
}


/*------------------------------------***  Init  ***------------------------------------*/
/*
access:			public	
overrides:
description: 	set up the symbol table for the built-in functions
ins: 			none
outs: 			none
notes:			
----------------------------------------------------------------------------------------*/

void	ZExpParser::Init()
{
  	int 	i;
  	symbol 	*ptr;
	
	st = NULL;
	expStr = NULL;
	
	// install mathematical functions...
  
  	for ( i = 0; gMathFunctions[i].fname != 0; i++ )
  	{
    	ptr = Put( gMathFunctions[i].fname, FUNCTION );
   		ptr->value.func = gMathFunctions[i].fnct;
  	}
  	
  	// also include a constant for pi...
  	
  	SetSymbolValue( "pi", pi );
}


/*----------------------------------***  Evaluate  ***----------------------------------*/
/*
access:			public	
overrides:
description: 	evaluate a function or assign a value to a variable
ins: 			<expression> the string to evaluate
outs: 			the numerical result of the evaluation
notes:			this does an awful lot - refer to the implementation notes
----------------------------------------------------------------------------------------*/

double_t	ZExpParser::Evaluate( const char* expression )
{
	expStr = const_cast<char*>(expression);
	result = 0.0;
	
	yyparse( this );

	// return the result...

	return result;
}



/*-------------------------------***  SetSymbolValue  ***-------------------------------*/
/*
access:			public	
overrides:
description: 	create or assign a variable's value
ins: 			<aName> the variable name
				<aValue> the value to assign to it
outs: 			none
notes:			refer to the implementation notes
----------------------------------------------------------------------------------------*/

void	ZExpParser::SetSymbolValue( const char* aName, const double_t aValue )
{
	symbol* p;
	
	p = Get( aName );
	
	if ( p == NULL )
		p = Put( aName, VAR );

	//FailNIL( p );
	
	if ( p )
		p->value.var = aValue;
}



/*-------------------------------------***  Get  ***------------------------------------*/
/*
access:			public	
overrides:
description: 	get a symbol from the parser's local symbol table
ins: 			<aName> the variable name to obtain
outs: 			pointer to the symbol itself
notes:			internal method not for app use generally
----------------------------------------------------------------------------------------*/

symbol*	ZExpParser::Get( const char* aName )
{
	symbol *ptr;
  	
  	for ( ptr = st; ptr != NULL; ptr = ptr->next )
  	{
    	if ( strcmp( ptr->name, aName ) == 0 )
      		return ptr;
    }
  	return NULL;
}


/*-------------------------------------***  Put  ***------------------------------------*/
/*
access:			public	
overrides:
description: 	add a symbol to the local symbol table
ins: 			<aName> the variable name to assign
				<aType> the symbol type. At present, the only allowed values are VAR and FUNCTION
outs: 			pointer to the symbol itself
notes:			internal method not for app use generally
----------------------------------------------------------------------------------------*/

symbol*	ZExpParser::Put( const char* aName, const int aType )
{
	symbol *ptr;
	
  	ptr = (symbol*) malloc ( sizeof( symbol ));
  	
  	ptr->name = (char*) malloc( strlen( aName ) + 1 );
  	strcpy( ptr->name, aName );
  	ptr->type = aType;
  	ptr->value.var = 0; /* preset value to 0 even if a function */
  	
  	ptr->next = st;
  	st = ptr;
 	
 	return ptr;
}


/*----------------------------------***  SetResult  ***---------------------------------*/
/*
access:			public	
overrides:
description: 	set the value of the return result
ins: 			<v> result value
outs: 			none
notes:			internal method not for app use generally
----------------------------------------------------------------------------------------*/

void	ZExpParser::SetResult( double_t v )
{
	result = v;
}				

#endif