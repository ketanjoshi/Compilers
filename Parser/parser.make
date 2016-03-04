CC=cc
LEX=lex
FILES_TO_REMOVE=lex.yy.c *.exe *.txt *.out
PT_FILE=input1.pt
SFP_FILE=sample.sfp

clean:
	@echo "Removing intermediate and temp files..."
	rm -f $(FILES_TO_REMOVE)

build:
	@echo "Compiling lexer..."
	$(LEX) SFP.l
	@echo "Compiling parser..."
	$(CC) parser.c lex.yy.c -o parser.exe

exec:
	@echo "Executing parser..."
	./parser.exe $(PT_FILE) <$(SFP_FILE)
	@echo "Parsing completed."

all: clean build exec