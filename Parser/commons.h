
char offset	= '0';

int charToDigit(char c) {
	int n = c - offset;
	return (n >= 0 && n <= 9) ? n : -1;
}

char digitToChar(int n) {
	return (n >= 0 && n <= 9)
			? (char) (n + offset)
			: '#';
}

int getIndexT(char c) {
	switch(c) {
		case '{'	: return 1;
		case '}'	: return 2;
		case 'l'	: return 3;
		case 'p'	: return 4;
		case '='	: return 5;
		case 'f'	: return 6;
		case 'n'	: return 7;
		case 'x'	: return 8;
		case '$'	: return 9;
		default		: return 0;
	}
}

int getIndexNT(char c) {
	switch(c) {
		case 'P'	: return 10;
		case 'T'	: return 11;
		case 'S'	: return 12;
		case 'R'	: return 13;
		case 'C'	: return 14;
		default		: return 0;
	}
}

int isShiftAction(char *action) {
	int diff = action[0] - offset;
	return diff >= 0 && diff <= 9 ? 1 : 0;
}