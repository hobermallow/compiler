%{
#include "bison.tab.h"	
#include "type_definitions.h"
//dichiaro le variabili globali per la gesstione delle definizioni di funzione
extern int functionDefinitions;
extern func* func_list;

%}

%%

"scanf" {printf("SCANF\n"); return SCANF; }
"printf" {printf("PRINTF\n"); return PRINTF; }
"matrix" {printf("MATRIX\n");return MATRIX;}
";" {printf("SEMI_COLON\n");return SEMI_COLON; }
"newtype" {printf("NEWTYPE\n"); return NEWTYPE; }
"(" {printf("OP\n"); return OP;}
")" {printf("CP\n"); return CP;}
"record" {printf("RECORD\n"); return RECORD; }
"array" {printf("ARRAY\n"); return ARRAY; }
"integer" {printf("INTEGER\n"); yylval.str = strdup(yytext); return INTEGER; }
"boolean" {printf("BOOLEAN\n"); yylval.str = strdup(yytext); return BOOLEAN; }
"[" {printf("OSP\n"); return OSP; }
"]" {printf("CSP\n"); return CSP; }
"floating" {printf("FLOATING\n"); yylval.str = strdup(yytext);  return FLOATING; }
"char" {printf("CHAR\n"); yylval.str = strdup(yytext); return CHAR; }
"string" {printf("STRING\n"); yylval.str = strdup(yytext); return STRING_TYPE; }
"," {printf("COMMA\n"); return COMMA; }
"=" {printf("ASSIGN\n"); return ASSIGN; }
"-" {printf("MINUS\n"); return MINUS; }
"->" {printf("ARROW\n"); return ARROW; }
"||" {printf("OR\n"); return OR; }
"&&" {printf("AND\n");  return AND; }
"!" {printf("NOT\n");  return NOT; }
"==" {printf("EQUAL\n");  return EQUAL; }
"!=" {printf("NOTEQUAL\n"); return NOTEQUAL; }
"+" {printf("PLUS\n"); return PLUS; }
"*" {printf("MUL\n");  return MUL; }
"#" {printf("EXP\n"); return EXP; }
"/" {printf("DIV\n");  return DIV; }
"func" {printf("FUNC\n");  functionDefinitions = 1; change_environment();printf("Nuovo environment\n"); return FUNC; }
func[ ]+exec {int a = check_recursive_definitions(); if(a==0) { printf("Errore nelle definizioni ricorsive dei tipi\n"); exit(1); } printf("FUNC_EXEC\n"); change_environment(); printf("Nuovo environment\n"); return FUNC_EXEC; }
":" {printf("COLON\n");  return COLON; }
"begin" {printf("BEG\n"); return BEG; }
"end" {	
	printf("END\n"); 
	//controllo le definizioni ricorsive di tipo
	int a =	check_recursive_definitions();
	if(a == 0) {
		printf("//lexer.l: errore nelle definizioi ricorsive di tipo\n");
		exit(1);
	}
	//se sono all'interno della definizione di una funzione, debbo controllare le dichiarazioni degli identificatori di variabile utilizzati
	if(functionDefinitions == 1) {
		//controllo che, per tutti gli identificatori utilizzati che non siano identificatori di funzione
		//sia presente un record nella symbol table
		check_function_definition_identifiers();
		//modifico il valore del flag in bison
	}
	pop_environment();
	printf("Pop environment\n");
	return END; 
	}
"return" {printf("RETURN\n"); return RETURN; }
"{" {printf("OGP\n"); return OGP; }
"}" {printf("CGP\n"); return CGP; }
"new" {printf("NEW\n"); return NEW; }
"if" {printf("IF\n"); return IF; }
"else" {printf("ELSE\n"); return ELSE; }
"loop" {printf("LOOP\n"); return LOOP; }
"free" {printf("FREE\n"); return FREE; }
">" {printf("GRT\n"); return GRT; }
"<" {printf("LST\n"); return LST; }
">=" {printf("GTE\n"); return GTE; }
"<=" {printf("LTE\n"); return LTE; }
"newvars" {printf("NEWVARS\n"); return NEWVARS; }
"then" {printf("THEN\n"); return THEN; }
"true" {printf("BOOLEAN_CONSTANT\n"); yylval.str = (char*) strdup(yytext); return BOOLEAN_CONSTANT; }
"false" {printf("BOOLEAN_CONSTANT\n"); yylval.str = (char*) strdup(yytext); return BOOLEAN_CONSTANT;}
[1-9][0-9]* {printf("INTEGER_CONSTANT\n"); printf("%d\n", atoi(yytext)); yylval.intval = atoi(yytext); return INTEGER_CONSTANT; }
"'"[:alnum:]*"'"  {printf("CHARACTER_CONSTANT\n"); yylval.str = (char*) strdup(yytext); return CHARACTER_CONSTANT; }
"\""[:alnum:]*"\""  {printf("STRING\n"); yylval.str = (char*) strdup(yytext); return STRING; }
[0-9]*"."[0-9]* {printf("FLOATING_CONSTANT\n"); yylval.dval = atof(yytext); return FLOATING_CONSTANT; }
"overload" {printf("OVERLOAD\n"); change_environment(); printf("Nuovo environment\n");return OVERLOAD; }
[_a-zA-Z][_a-zA-Z0-9]{0,30} {printf("IDENTIFIER\n");  printf("%s\n", yytext); yylval.id = (char*) strdup(yytext); return IDENTIFIER;}
"\t"
" "
"\n" 
<<EOF>> {return EOF_TOKEN; }
%%

//main(int argc, char* argv[]) {
//	FILE* f;
//	if(argc == 2) {
//		f = fopen(argv[1], "r");
//		yyin = f;	
//	}
//	yyparse();
//}
