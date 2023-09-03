%{
	
	#include <cstdlib>
	#include <string>
	
	class Symbol;
	
	#include "y.tab.h"
	
	extern "C" {
		int yylex(void);
	}
	
	extern unsigned lineCount;
	extern YYSTYPE yylval;
	
	extern const int V_TYPE;
	extern const int I_TYPE;
	extern const int F_TYPE;
	
	extern void* new_symbol(const std::string &name, int type);
	
%}

%%

[\t\r ]+		/* ignore white space */ ;

\%\%[^\n]*\n	/* ignore comment */	{ lineCount++; }

[Pp][Rr][Oo][Gg][Rr][Aa][Mm]		{ return PROGRAM; }		// PROGRAM

[Bb][Ee][Gg][Ii][Nn]				{ return BEGIN_; }		// BEGIN

[Ee][Nn][Dd]						{ return END; }			// END

[Ii][Ff]							{ return IF; }			// IF

[Tt][Hh][Ee][Nn]					{ return THEN; }		// THEN

[Ee][Ll][Ss][Ee]					{ return ELSE; }		// ELSE

[Ee][Nn][Dd][Ii][Ff]				{ return ENDIF; }		// ENDIF

[Ff][Oo][Rr]						{ return FOR; }			// FOR

[Tt][Oo]							{ return TO; }			// TO

[Dd][Oo][Ww][Nn][Tt][Oo]			{ return DOWNTO; }		// DOWNTO

[Ss][Tt][Ee][Pp]					{ return STEP; }		// STEP

[Ee][Nn][Dd][Ff][Oo][Rr]			{ return ENDFOR; }		// ENDFOR

[Ww][Hh][Ii][Ll][Ee]				{ return WHILE; }		// WHILE

[Ee][Nn][Dd][Ww][Hh][Ii][Ll][Ee]	{ return ENDWHILE; }	// ENDWHILE

[Dd][Ee][Cc][Ll][Aa][Rr][Ee]		{ return DECLARE; }		// DECLARE

[Aa][Ss]							{ return AS; }			// AS

[Ii][Nn][Tt][Ee][Gg][Ee][Rr]		{ return INTEGER; }		// INTEGER

[Ff][Ll][Oo][Aa][Tt]				{ return FLOAT; }		// FLOAT

[0-9]+							{ yylval.symbol = new_symbol(std::to_string(atoi(yytext)), I_TYPE); return INTEGER_LITERAL; }	// integer literal

([0-9]*([0-9]\.|\.[0-9])[0-9]*|([0-9]+|[0-9]*([0-9]\.|\.[0-9])[0-9]*)[Ee][+-]?[0-9]+)		{ yylval.symbol = new_symbol(std::to_string(atof(yytext)), F_TYPE); return FLOAT_LITERAL; }		// float point literal

\:=		{ return ASSIGN; }			// assign operation :=	

!=		{ return NOT_EQUAL; }		// not equal !=

==		{ return EQUAL; }			// equal ==

\>		{ return GREATER; }			// greater than >

\<		{ return LESS; }			// less than <

\>=		{ return GREATERE_QUAL; }	// greater or equal >=

\<=		{ return LESSE_QUAL; }		// less or equal <=

&&		{ return AND; }				// and &&

\|\|	{ return OR; }				// OR ||

[A-Za-z][A-Za-z0-9_]*		{ yylval.symbol = new_symbol(std::string(yytext), V_TYPE); return ID; }	// ID

\n		{ lineCount++; }

.		{ return yytext[0]; }

%%

