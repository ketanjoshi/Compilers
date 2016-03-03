%{

/* Ketan Joshi */

#include "tokens.h"

%}

newline		[\n]
obrace		"{"
cbrace		"}"
print 		"print"
loop		"loop"
binop		"+"|"*"
assignop	"="
zeros		"00"([0])*
integer		"0"|(-?[ ]?[1-9][0-9]*)
float		{integer}\.[0-9]+
identifier	[a-z]+
space		[ \t]+
errors		.

%%

{space}			{ }
{newline}		{ yylineno++; }
{obrace}		{ return O_BRACE; }
{cbrace}		{ return C_BRACE; }
{integer}		{ return NUM; }
{zeros}			{ /* Neglecting leading zeros */ }
{float}			{ return NUM; }
{print}			{ return PRINT; }
{loop}			{ return LOOP; }
{identifier}	{ return ID; }
{binop}			{ return BIN_OP; }
{assignop}		{ return ASSIGN_OP; }
{errors}		{ return ERROR; }

%%

int yywrap(void) {
	return 1;
}