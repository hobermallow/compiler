.PHONY: clean
parser: bison.y lexer.l SM.h
	bison -d bison.y
	flex lexer.l
	gcc -o $@ bison.tab.c lex.yy.c -lfl



clean : 
	rm bison.tab.*
	rm lex.yy.c
	rm parser
