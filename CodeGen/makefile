all:
	rm -f lex.yy.c y.tab.c symboltable.out cfp.exe
	yacc -d FP.y
	lex FP.l
	gcc lex.yy.c y.tab.c -o cfp.exe
	./cfp.exe sample.mc < sample.fp
