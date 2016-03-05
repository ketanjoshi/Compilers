// Common headers
#include "headers.h"

// Lexer's external functions and variables
extern int yylex();
extern int yylineno;
extern char* yytext;

// Constants
char* tokenNames[]	= {"ERROR", "O_BRACE", "C_BRACE", "LOOP", "PRINT", "ASSIGN_OP", "BIN_OP", "NUM", "ID", "DOLLAR"};
char T[]			= {'#', '{', '}', 'l', 'p', '=', 'f', 'n', 'x', '$'};
char NT[]			= {'#', 'P', 'T', 'S', 'R', 'C'};
int numOfTokens		= 9;

// Parsing table variables
char title[15][2];
char actionTab[50][20][25];
int entryCt			= 1;

// Parser stack variables
TreeNode* stack[1000];
int top				= 0;

// Parse tree head;
TreeNode* head;

// Current parser state
int currState;

// File logger
FILE *logger;
FILE *treeWriter;


/*
* Read input file and initialise parse tables.
*/
void initialiseTables(char *filename) {
	FILE *fin = fopen(filename, "r");
	if(fin == NULL) {
		fprintf(logger, "Cannot open input file : %s\n", filename);
    	return;
	}

	char curr[10];
	char s[10];

	fscanf(fin, "%s%s%s%s%s%s%s%s%s%s%s%s%s%s\n", 
		title[0], title[1], title[2], title[3], title[4], title[5], title[6],
		title[7], title[8], title[9], title[10], title[11], title[12], title[13]);
	while(!feof(fin)) {
		int temp;
		fscanf(fin, "%d%s%s%s%s%s%s%s%s%s%s%s%s%s%s\n", &temp,
			actionTab[entryCt][1], actionTab[entryCt][2], actionTab[entryCt][3], actionTab[entryCt][4], actionTab[entryCt][5],
			actionTab[entryCt][6], actionTab[entryCt][7],actionTab[entryCt][8], actionTab[entryCt][9], actionTab[entryCt][10],
			actionTab[entryCt][11], actionTab[entryCt][12], actionTab[entryCt][13], actionTab[entryCt][14]);
		entryCt++;
	}
}

/*
* Print parsing tables.
*/
void printTables() {
	int i;
	for(i = 1; i < entryCt; i++) {
		fprintf(logger, "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n", 
			actionTab[i][1], actionTab[i][2], actionTab[i][3], actionTab[i][4], actionTab[i][5],
			actionTab[i][6], actionTab[i][7], actionTab[i][8], actionTab[i][9], actionTab[i][10],
			actionTab[i][11], actionTab[i][12], actionTab[i][13], actionTab[i][14]);
	}
}

/*
* Returns goto state epending on previous state and current non terminal.
*/
int getGotoState(int prevState, char currentNT) {
	int indexNT = getIndexNT(currentNT);
	return atoi(actionTab[prevState][indexNT]);
}

/*
* Reduces parse stack by length of 'len'.
*/
TreeNode* reduce(int len) {
	int i;
	TreeNode* cur = stack[top--];
	for(i = 0; i < len - 1; i++) {
		TreeNode* prev = stack[top--];
		if(prev->sib != NULL) {
			fprintf(logger, "\nAnomalous behaviour, sibling not null");
			exit(0);
		}
		prev->sib = cur;
		cur = prev;
	}
	return cur;
}

/*
* Prints parsing stack.
*/
void printStack() {
	int i = 0;
	fprintf(logger, "Stack :");
	for(i = 0; i <= top; i++) {
		//fprintf(logger, "%c,%d|", stack[i]->symbol, stack[i]->state);
		fprintf(logger, "%c,%d|", stack[i]->symbol, stack[i]->state);
	}
	//fprintf(logger, "\n");
	fprintf(logger, "\n");
}

/*
* Pushes given node on the stack.
*/
void shift(TreeNode* node) {
	stack[++top] = node;
}

/*
* Recursively prints the tree starting from input node. Spaces and index are 
* used internally to correctly show child and siblings of particular node.
*/
void printTree(TreeNode* node, int spaces) {
	if(node == NULL) return;

	int i;
	for(i = 0; i < spaces; i++) {
		fprintf(treeWriter, "  ");
	}

	fprintf(treeWriter, "(%s,%c)\n", node->value, node->symbol);

	printTree(node->child, spaces + 2);
	printTree(node->sib, spaces);
}

/*
* Prints a particular branch i.e node, its child and the siblings of the child.
*/
void printBranch(TreeNode* node) {
	TreeNode* n = node;
	fprintf(logger, "Reduction : (%c,%d) ---> ", n->symbol, n->state);
	n = n->child;
	while(n != NULL) {
		fprintf(logger, "(%c,%d) -> ", n->symbol, n->state);
		n = n->sib;
	}
	fprintf(logger, "NULL\n");
}

void printParseTree() {
	// Initial call
	printTree(head, 0);
}

/*
* Processes the input token using parse tables.
*/
void processToken(int token) {
	int isTokenConsumed = 1;

	while(isTokenConsumed) {
		char *action = actionTab[currState][token];
		int isShift = isShiftAction(action);

		if(isShift) {
			// Shift action
			int newState = atoi(action);
			if(newState == 0) {
				// Error state, exit.
				fprintf(logger, "ERROR!\n");
				exit(0);
			}
			else if(newState == 9999) {
				// Accept state, return.
				fprintf(logger, "Successfully parsed\n");
				return;
			}

			TreeNode* newNode = buildNode(T[token], yytext, newState);
			shift(newNode);
			currState = newState;
			isTokenConsumed = 0;
		}
		else {
			// Reduce action
			char prodLhs = action[0];
			char prodRhsStart = action[2];
			int productionLength = strlen(action) - 2;

			// Pop stack until we find prodRhsStart character
			TreeNode* childNode = reduce(productionLength);

			int gotoState = getGotoState(stack[top]->state, prodLhs);

			TreeNode* reducedNode = buildNode(prodLhs, "", gotoState);
			reducedNode->child = childNode;
			head = reducedNode;

			shift(reducedNode);

			currState = gotoState;

			printBranch(reducedNode);
		}
		printStack();
	}
}

/*
* Initialises environment (stack, logger, current state etc.).
*/
void initialiseEnv() {
	stack[top] = buildNode('#', "default", 1);
	currState = 1;
	logger = fopen("log.out", "w+");
	treeWriter = fopen("parsetree.out", "w+");
}

/*
* Main function.
*/
int main(int argc, char *argv[]) {

	initialiseTables(argv[1]);
	//printTables();
	initialiseEnv();

	int token = yylex();
	while(token) {
		processToken(token);
		token = yylex();
	}

	// Input ends, process end symbol '$'
	processToken(DOLLAR);

	// Print parse tree
	printParseTree();

	return 0;
}

