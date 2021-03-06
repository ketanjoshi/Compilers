%{

#include<stdio.h>
#include<stdlib.h>
#include<string.h>


extern struct table {
	int isFunction;
	int isConstant;
	char symbol[20];
	char value[20];
	int storedMemAddr;

	// Function related
	int retValMemIndx;
	int retAddrMemIndx;
	int entryPoint;
	char retArgName[10];
	char params[50];

}symbolTable[30];


extern int symbolCount;
extern int nextFreeMemLoc;

extern int findSymbolIndex(char str[]);
extern void addSymbol(char str[]);
extern void showSymbolTable();


int registersOccupancy[] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
int printCorrectedInstr(char str[], int);
void clearRegister(int);
void occupyRegister(int);
int isNumber(char str[]);

int codeOffset = 1;

extern FILE *yyin;
extern int yylineno;

FILE *fpo;


%}

%union{
	char str[800000];
}


%token <str> ID CHARS PROGRAM MAIN FUNCTIONS CONSTANTS RETURN PRED_FUNC
%token <str> IF THEN ELSE WHILE DO PRINT READ IDENTIFIER LOOP
%token <str> INTEGER FLOAT
%token <str> O_BRACE C_BRACE ASSIGN_OP BOOL COMPARE_OP

%type <str> constDef constName S_Param assgnStmt param P_Param param1
%type <str> readStmt id ifStmt exp program printStmt stmts stmt
%type <str> loopStmt whileStmt args arg retArg funcName funcDef funcDefs

%start program


%%

program		: 
		CONSTANTS constDefs
		FUNCTIONS funcDefs
		MAIN stmts 	{
			fprintf(fpo, "goto %d;\n", codeOffset + 1);
			int line = printCorrectedInstr($4, 1);
			printCorrectedInstr($6, line);
			fprintf(fpo, "load R0 99;");	// Ending instruction
		}
		;

constDefs 	:
		constDef constDefs 	| 
		;

constDef 	:
		O_BRACE constName S_Param C_BRACE {
			// Save the symbol value and type
			int index = findSymbolIndex($2);
			strcpy(symbolTable[index].value, $3);
			symbolTable[index].isConstant = 1;
		}
		;

constName 	:
		IDENTIFIER	{strcpy($$, $1);}
		;

S_Param 	:
		INTEGER		{ strcpy($$, $1);}|
		FLOAT		{ strcpy($$, $1);}|
		BOOL 		{ strcpy($$, $1);}|
		CHARS		{ strcpy($$, $1);}
		;

stmts 		:
		stmt stmts 	{ sprintf($$, "%s%s", $1, $2); } | 
		{ sprintf($$, "%c", '\0'); }
		;

stmt 		:
		assgnStmt 	|
		printStmt	|
		readStmt	|
		ifStmt 		|
		whileStmt 	|
		loopStmt
		;

assgnStmt 	:
		O_BRACE ASSIGN_OP IDENTIFIER param C_BRACE 	{
			int index = findSymbolIndex($3);

			// We have to change the contents of M[storedMemAddr] for this symbol
			if(isMemLoc($4)) {
				int r = getAvailableRegister();
				char loadInstr[20];
				sprintf(loadInstr, "load R%d %s\n", r, $4);
				sprintf($$, "%sstore M[%d] R%d\n", loadInstr, symbolTable[index].storedMemAddr, r);
				clearRegister(r);
			}
			else if(isNumber($4)) {
				sprintf($$, "store M[%d] %s\n", symbolTable[index].storedMemAddr, $4);
			}
			else if($4[0] == 'l') {
				// load instruction => result is in M[0]
				int r = getAvailableRegister();
				sprintf($$, "%sload R%d M[0]\nstore M[%d] R%d\n", $4, r, symbolTable[index].storedMemAddr, r);
				clearRegister(r);
			}
			else {
				sprintf($$, "prob: %s : %s : %s\n", $2, $3, $4);
			}
		}
		;

param 		:
		O_BRACE funcName param1 C_BRACE		{
			// Do the parameter mapping
			// call the function
			// Store the result in R1
			int index = findSymbolIndex($2);
			// for each value in params - copy actual params
			char par[6];
			int i = 0;
			int ind = 0;
			int paramIndex = 0;
			char actualParams[5][8], formalParams[5][8];
			while(symbolTable[index].params[i] == ' ') i++;
			while(symbolTable[index].params[i] != '\0') {
				if(symbolTable[index].params[i] == ' ') {
					// copy actual param to this param
					par[ind] = '\0';
					strcpy(formalParams[paramIndex++], par);
					ind = 0; i++;
				}
				else
					par[ind++] = symbolTable[index].params[i++];
			}
			i = 0; ind = 0; paramIndex = 0;
			while($3[i] == ' ') i++;
			while($3[i] != '\0') {
				if($3[i] == ' ') {
					// copy actual param to this param
					par[ind] = '\0';
					strcpy(actualParams[paramIndex++], par);
					ind = 0; i++;
				}
				else
					par[ind++] = $3[i++];
			}
			int r = getAvailableRegister();
			char loadInstr[20];
			char storeInstr[20];
			strcpy($$, "");
			for(i = 0; i < paramIndex; i++) {
				// write copy instructions
				sprintf(loadInstr, "load R%d %s\n", r, actualParams[i]);
				sprintf(storeInstr, "store %s R%d\n", formalParams[i], r);
				strcat($$, loadInstr);
				strcat($$, storeInstr);
			}
			strcat($$, "load R0 2\n");
			
			char goto1Instr[20];
			sprintf(goto1Instr, "|goto %d\n", symbolTable[index].entryPoint);
			strcat($$, goto1Instr);

			char storeRetInstr[20];
			sprintf(storeRetInstr, "load R%d %s\nstore M[0] R%d\n", r, symbolTable[index].retArgName, r);
			strcat($$, storeRetInstr);
			
			clearRegister(r);

		}	|
		O_BRACE PRED_FUNC param param C_BRACE 	{
			//int v1 = getAvailableRegister();
			int v1 = 3;
			char loadInstr[20];
			sprintf(loadInstr, "load R1 %s\n", $3);
			// store result in M[0]
			// Calculate result in R1 and move it to M[0]
			char calcInstr[40];
			if(strcmp($2, "+") == 0) {
				// addition
				sprintf(calcInstr, "add R1 R1 %s\nstore M[0] R1\n",
							 $4);
			}
			else if(strcmp($2, "-") == 0) {
				// subtraction
				sprintf(calcInstr, "sub R1 R1 %s\nstore M[0] R1\n",
							 $4);
			}
			else if(strcmp($2, "*") == 0) {
				// multiplication
				sprintf(calcInstr, "mul R1 R1 %s\nstore M[0] R1\n",
							 $4);
			}
			else if(strcmp($2, "/") == 0) {
				// division
				sprintf(calcInstr, "div R1 R1 %s\nstore M[0] R1\n",
							 $4);
			}
			sprintf($$, "%s%s", loadInstr, calcInstr);
			clearRegister(v1);

		}	|
		O_BRACE PRED_FUNC param param param C_BRACE 	{
			//int v1 = getAvailableRegister();
			int v1 = 3;
			char loadInstr[20];
			sprintf(loadInstr, "load R1 %s\n", $3);
			// store result in M[0]
			// Calculate result in R1 and move it to M[0]
			char calcInstr[50];
			if(strcmp($2, "+") == 0) {
				// addition
				sprintf(calcInstr, "add R1 R1 %s\nadd R1 R1 %s\nstore M[0] R1\n",
							 $4, $5);
			}
			else if(strcmp($2, "-") == 0) {
				// subtraction
				sprintf(calcInstr, "sub R1 R1 %s\nsub R1 R1 %s\nstore M[0] R1\n",
							 $4, $5);
			}
			else if(strcmp($2, "*") == 0) {
				// multiplication
				sprintf(calcInstr, "mul R1 R1 %s\nmul R1 R1 %s\nstore M[0] R1\n",
							 $4, $5);
			}
			else if(strcmp($2, "/") == 0) {
				// division
				sprintf(calcInstr, "div R1 R1 %s\ndiv R1 R1 %s\nstore M[0] R1\n",
							 $4, $5);
			}
			sprintf($$, "%s%s", loadInstr, calcInstr);
			clearRegister(v1);

		}	|
		INTEGER		{ strcpy($$, $1); } |
		FLOAT		{ strcpy($$, $1); } |
		IDENTIFIER 	{
			int index = findSymbolIndex($1);
			if(symbolTable[index].isConstant) {
				strcpy($$, symbolTable[index].value);
			}
			else {
				sprintf($$, "M[%d]", symbolTable[index].storedMemAddr);
			}
		}
		;


param1 		:
		param param1 	{
			sprintf($$, "%s %s", $1, $2);
		}	| 	{
			sprintf($$, "%c", '\0');
		}
		;


printStmt 	:
		O_BRACE PRINT P_Param C_BRACE 	{
			sprintf($$, "print %s\n", $3);
		}
		;

P_Param 	:
		IDENTIFIER 		{
			int index = findSymbolIndex($1);
			if(symbolTable[index].isConstant)
				sprintf($$, "%s", symbolTable[index].value);
			else
				sprintf($$, "M[%d]", symbolTable[index].storedMemAddr);
		}	|

		S_Param 	{
			sprintf($$, "%s", $1);
		}		|

		IDENTIFIER P_Param 	{
			int index = findSymbolIndex($1);
			if(symbolTable[index].isConstant) {
				sprintf($$, "%s %s ", symbolTable[index].value, $2);
			}
			else {
				sprintf($$, "M[%d] %s", symbolTable[index].storedMemAddr, $2);
			}
		}	|

		S_Param P_Param {
			sprintf($$, "%s %s", $1, $2);
		}
		;

readStmt 	:
		O_BRACE READ id C_BRACE 	{
			strcpy($$, $3);
		}
		;


id 		:
		id IDENTIFIER {
			int index = findSymbolIndex($2);
			sprintf($$, "%sread M[%d]\n", $1, symbolTable[index].storedMemAddr);
		}	|
		IDENTIFIER 	{
			int index = findSymbolIndex($1);
			sprintf($$, "read M[%d]\n", symbolTable[index].storedMemAddr);
		}
		;

ifStmt 		:
		O_BRACE IF exp THEN stmts ELSE stmts C_BRACE 	{
			int expLines = getLineCount($3);
			int ifLines = getLineCount($5);
			int elseLines = getLineCount($7);
// exp -> if R -> else block -> goto end -> if block
			int r = getRegNumFromExp($3);
			char ifInstr[30];
			sprintf(ifInstr, "if R%d %d\n", r, elseLines + 2);
			char gotoInstr[10];
			sprintf(gotoInstr, "goto %d\n", ifLines + 1);
			sprintf($$, "%s%s%s%s%s", $3, ifInstr, $7, gotoInstr, $5);
		}
		;


exp 		:
		O_BRACE COMPARE_OP param param C_BRACE 	{
			int r1 = getAvailableRegister();
			int r2 = getAvailableRegister();

			int index = findSymbolIndex($3);
			if(isMemLoc($3)) {
				char loadInstr[20];
				sprintf(loadInstr, "load R%d %s\n", r2, $3);
				sprintf($$, "%s%s R%d R%d %s\n", loadInstr, $2, r1, r2, $4);
			}
			else if(isNumber($3)) {
				sprintf($$, "%s R%d %s %s\n", $2, r1, $3, $4);
			}
			else {
				sprintf($$, "prob: %s : %s : %s\n", $2, $3, $4);
			}
			clearRegister(r1);
			clearRegister(r2);
		}	|
		BOOL 	{ 
			int r = getAvailableRegister();
			sprintf($$, "load R%d %s\n", r, $1);
			clearRegister(r);
		}
		;

whileStmt 	:
		O_BRACE WHILE exp stmts C_BRACE 	{
			int expLines = getLineCount($3);
			int stmtsLines = getLineCount($4);
// exp -> if stmt -> goto end -> stmts -> goto start
			int r = getRegNumFromExp($3);
			char ifInstr[20];
			sprintf(ifInstr, "if R%d %d\n", r, 2);
			char gotoEndInstr[10];
			sprintf(gotoEndInstr, "goto %d\n", stmtsLines + 2);
			char gotoStartInstr[10];
			sprintf(gotoStartInstr, "goto %d\n", -(stmtsLines + expLines + 2));
			sprintf($$, "%s%s%s%s%s", $3, ifInstr, gotoEndInstr, $4, gotoStartInstr);
		}
		;


loopStmt 	:
		O_BRACE LOOP IDENTIFIER stmts C_BRACE 	{
			int r = 2;
			// store this register with IDENTIFIER value
			// decrement after each execution
			// compare it with 0
			int stmtsLines = getLineCount($4);
			int index = findSymbolIndex($3);

			char storeInstr[20];
			sprintf(storeInstr, "load R%d M[%d]\n", r, symbolTable[index].storedMemAddr);
			int testReg = getAvailableRegister();
			char compareInstr[20];
			sprintf(compareInstr, ">= R%d R%d 1\n", testReg, r);
			char decrementInstr[20];
			sprintf(decrementInstr, "sub R%d R%d 1\n", r, r);
			char ifInstr[30];
			sprintf(ifInstr, "if R%d %d\n", testReg, 2);
			char gotoEndInstr[10];
			sprintf(gotoEndInstr, "goto %d\n", stmtsLines + 3);
			char gotoStartInstr[10];
			sprintf(gotoStartInstr, "goto %d\n", -(stmtsLines + 4));
// store instr -> test -> if -> goto end -> stmts -> decrement -> goto test
			sprintf($$, "%s%s%s%s%s%s%s",
				storeInstr, compareInstr, ifInstr, gotoEndInstr, $4, decrementInstr, gotoStartInstr);

			clearRegister(testReg);

		}
		;


funcDefs 	:
		funcDef funcDefs 	{
			sprintf($$, "%s%s", $1, $2);
		}	|  {
			sprintf($$, "%c", '\0');
		}
		;

funcDef 	:
		O_BRACE funcName args RETURN retArg stmts C_BRACE {
			// Caller function would set:
			// 1. the actual params
			// 2. store next instr num in register
			int index = findSymbolIndex($2);
			strcpy(symbolTable[index].params, $3);
			strcpy(symbolTable[index].retArgName, $5);
			symbolTable[index].entryPoint = codeOffset + 1;

			sprintf($$, "%sgoto R0\n", $6);
			codeOffset++;
			codeOffset += getLineCount($6);
		}
		;

args 		:
		arg { strcpy($$, $1); }	|
		arg args { sprintf($$, "%s %s", $1, $2); }
		;

arg 		:
		IDENTIFIER 	{
			int index = findSymbolIndex($1);
			sprintf($$, "M[%d] ", symbolTable[index].storedMemAddr);
		}
		;

retArg 		:
		IDENTIFIER 	{ 
			int index = findSymbolIndex($1);
			sprintf($$, "M[%d] ", symbolTable[index].storedMemAddr);
		}
		;

funcName	:
		IDENTIFIER 	{ 
			strcpy($$, $1);
			int index = findSymbolIndex($1);
			symbolTable[index].isFunction = 1;
			symbolTable[index].retValMemIndx = getNextFreeMemLoc();
			symbolTable[index].retAddrMemIndx = getNextFreeMemLoc();
		}
		;


%%
int getNextFreeMemLoc() {
	return nextFreeMemLoc++;
}

int getAvailableRegister() {

	// R0: for return address of a function call
	// i.e. function call return value or arithmetic operation
	int i;
	for(i = 4; i <= 9; i++) {
		if(registersOccupancy[i] == 0) {
			registersOccupancy[i] = 1;
			return i;
		}
	}
	return -1;
}

void clearRegister(int id) {
	registersOccupancy[id] = 0;
}

int getLineCount(char str[]) {
	int i = 0;
	int count = 0;
	while(str[i] != '\0') {
		count = str[i] == '\n' ? count + 1 : count;
		i++;
	}
	return count;
}

int getRegNumFromExp(char str[]) {
	int i = 0;
	while(str[i] != '\0') {
		if(str[i] == '>' || str[i] == '<' 
			|| str[i] == '=' || str[i] == '!')
			break;
		i++;
	}

	while(str[i++] != 'R');
	return str[i] - '0';
}

int extractLineNo(char str[], int startIndex, int lastIndex) {
	int i = str[startIndex] == '-' ? startIndex + 1 : startIndex;
	int num = 0;
	while(i <= lastIndex) {
		num = (num * 10) + (str[i] - '0');
		i++;
	}
	return str[startIndex] == '-' ? (-1) * num : num;
}

void printLine(char str[], int lastIndex, int lineCount) {
	int i;
	int actualLineNo;
	int correctLineNo;
	char buf[5];
	if(str[0] == 'i' && str[1] == 'f') {
		// IF statement
		actualLineNo = extractLineNo(str, 6, lastIndex);
		correctLineNo = lineCount + actualLineNo;
		str[6] = '\0';
		fprintf(fpo, "%s %d;\n", str, correctLineNo);
	}
	else if(str[0] == 'g' && str[1] == 'o'
			&& str[5] != 'R') {
		// GOTO statement
		actualLineNo = extractLineNo(str, 5, lastIndex);
		correctLineNo = lineCount + actualLineNo;
		str[5] = '\0';
		fprintf(fpo, "%s %d;\n", str, correctLineNo);
	}
	else if(strcmp(str, "load R0 2") == 0) {
		str[8] = '\0';
		fprintf(fpo, "%s %d;\n", str, lineCount + 2);
	}
	else if(str[0] == '|') {
		int i = 0;
		while(i < strlen(str) - 1) {
			str[i] = str[i + 1];
			i++;
		}
		str[i] = '\0';
		fprintf(fpo, "%s;\n", str);
	}
	else {
		fprintf(fpo, "%s;\n", str);
	}
}

int printCorrectedInstr(char str[], int offSet) {
	int i = 0;
	int lineno = offSet;
	char buff[300];
	int buffIndex = 0;
	while(str[i] != '\0') {
		if(str[i] != '\n') {
			buff[buffIndex++] = str[i++];
			continue;
		}
		lineno++;
		buff[buffIndex] = '\0';
		printLine(buff, buffIndex - 1, lineno);
		i++;
		buffIndex = 0;
	}
	return lineno;
}

int isNumber(char str[]) {
	int i = 0;
	while(str[i] == ' ') i++;
	if(str[i] != '0') {
		return atoi(str) == 0 ? 0 : 1;
	}
	return 1;
}

int isMemLoc(char str[]) {
	int i = 0;
	while(str[i] == ' ') i++;
	return str[i] == 'M' ? 1 : 0;
}

void main(int argc, char* argv[]) {
	fpo = fopen(argv[1],"w");
	yyin = stdin;
	yyparse();
	fclose(fpo);
	showSymbolTable();
}

int yyerror(char* s) {
	fprintf(stderr, "Parse error on line %d, %s\n", yylineno, s);
}

