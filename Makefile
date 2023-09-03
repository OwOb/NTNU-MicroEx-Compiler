all:
	lex micro-ex.l
	yacc -d micro-ex.y
	g++ -std=c++11 -O2 -lfl -ly *.cpp *.c -o micro-ex
	rm  lex.yy.c y.tab.h y.tab.c
