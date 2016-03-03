#include<string.h>

typedef struct Node {
	char symbol;
	char value[20];
	int state;
	struct Node* child;
	struct Node* sib;
}TreeNode;

TreeNode* buildNode(char v, char* val, int s) {
	TreeNode *newNode;
	newNode = (TreeNode*)malloc(sizeof(TreeNode));
	newNode->symbol = v;
	strcpy(newNode->value, val);
	newNode->state = s;
	newNode->child = NULL;
	newNode->sib = NULL;
	return newNode;
}