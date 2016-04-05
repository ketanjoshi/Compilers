%{

/* Ketan Joshi */

#include<stdio.h>
#include<string.h>
#include "y.tab.h"


struct table {
	int isFunction;
	int isConstant;
	char symbol[20];
	char value[20];
	int datatype;
	int storedMemAddr;

	// Function related
	int caller[10],callee[10];
	int retValMemIndx;
	int retAddrMemIndx;
	int entryPoint;
	char retArgName[10];
	char params[50];

}symbolTable[30];

int symbolCount = 0;
int nextFreeMemLoc = 4;

int findSymbolIndex(char str[]);
void addSymbol(char str[]);
void showSymbolTable();


%}

newline		[\n]
obrace		"{"
cbrace		"}"
bool		"T"|"F"
const 		"CONSTANTS"
functions	"FUNCTIONS"
main		"MAIN"
return		"return"
if			"if"
then		"then"
else		"else"
while		"while"
do			"do"
read		"read"
print 		"print"
loop 		"loop"
predfunc	"+"|"-"|"*"|"/"|"%"
compareop	"=="|"<"|"<="|"=>"|">"|"!="
assignop	"="
integer		"0"|(-?[ ]?[1-9][0-9]*)
zeros		"00"([0])*
float		{integer}\.[0-9]+
identifier	[a-z]+
chars		([a-zA-Z0-9"\n"" "])+
space		[ \t]+
errors		.

%%

{space}			{ }
{newline}		{ yylineno++; }
{obrace}		{ strcpy(yylval.str, yytext); return O_BRACE; }
{cbrace}		{ strcpy(yylval.str, yytext); return C_BRACE; }
{main}			{ strcpy(yylval.str, yytext); return MAIN; }
{functions}		{ strcpy(yylval.str, yytext); return FUNCTIONS; }
{const}			{ strcpy(yylval.str, yytext); return CONSTANTS; } 
{return}		{ strcpy(yylval.str, yytext); return RETURN; }
{if}			{ strcpy(yylval.str, yytext); return IF; }
{then}			{ strcpy(yylval.str, yytext); return THEN; }
{else}			{ strcpy(yylval.str, yytext); return ELSE; }
{do}			{ strcpy(yylval.str, yytext); return DO; }
{while}			{ strcpy(yylval.str, yytext); return WHILE; }
{loop}			{ strcpy(yylval.str, yytext); return LOOP; }
{integer}		{ 
					/*if(strlen(yytext) > 7)
						printf("ERROR : Integer cannot be greater than 8 digits\n", INTEGER, yytext);
					else
						printf("%d : INTEGER : %s\n", INTEGER, yytext);*/
					char s[5];
					sprintf(s, "%d", atoi(yytext));
					strcpy(yylval.str, s); return INTEGER;
				}
{zeros}			{ /* Neglecting leading zeros */ }
{float}			{ strcpy(yylval.str, yytext); return FLOAT; }
"\("{chars}"\)"			{ strcpy(yylval.str, yytext); return CHARS; }
{bool}			{ strcpy(yylval.str, yytext); return BOOL; }
{read}			{ strcpy(yylval.str, yytext); return READ; }
{print}			{ strcpy(yylval.str, yytext); return PRINT; }
{identifier}	{ 
					strcpy(yylval.str, yytext);
					addSymbol(yytext);
					return IDENTIFIER;
				}
{predfunc}		{ strcpy(yylval.str, yytext); return PRED_FUNC; }
{compareop}		{ strcpy(yylval.str, yytext); return COMPARE_OP; }
{assignop}		{ strcpy(yylval.str, yytext); return ASSIGN_OP; }
{errors}		{ printf("ERROR : line number %d : Unrecognizable token \'%s\'\n", yylineno, yytext); }

%%

int findSymbolIndex(char str[]) {
	int i;
	for(i = 0; i < symbolCount; i++) {
		if(strcmp(symbolTable[i].symbol, str) == 0) {
			// Symbol already present
			return i;
		}
	}
	return -1;
}

void addSymbol(char str[]) {
	if(findSymbolIndex(str) == -1) {
		strcpy(symbolTable[symbolCount].symbol, str);
		symbolTable[symbolCount].storedMemAddr = nextFreeMemLoc++;
		symbolCount++;
	}
}

void showSymbolTable() {
	int i, j = 0, k = 0;
	FILE *fp1 = fopen("symboltable.out", "w");
	fprintf(fp1, "\n\n\n SYMBOL TABLE: length = %d\n", symbolCount);
	fprintf(fp1, "\n_______________________________________________________________");
	fprintf(fp1, "\nIndex\tSymbol\t\tData Type\t\tEntry\t\tParams");
	fprintf(fp1, "\n_______________________________________________________________");
	for(i = 0; i < symbolCount; i++) {	
		j = 0;	
		fprintf(fp1, "\n%d)\t%s - M[%d]\t\t%d\t\t%d\t\t%s", i,
				symbolTable[i].symbol,
				symbolTable[i].storedMemAddr,
				symbolTable[i].datatype,
				symbolTable[i].entryPoint,
				symbolTable[i].params);
	}
	fprintf(fp1, "\n_______________________________________________________________\n\n");
}

int yywrap() {
	return 1;
}