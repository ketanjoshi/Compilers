all:
	rm -f lex.yy.c y.tab.c symboltable.out codegen.exe
	yacc -d FP.y
	lex FP.l
	gcc lex.yy.c y.tab.c -o codegen.exe
	./codegen.exe
