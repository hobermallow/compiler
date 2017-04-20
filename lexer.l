%{
#include "bison.tab.h"	
#include "type_definitions.h"
//dichiaro le variabili globali per la gesstione delle definizioni di funzione
extern int functionDefinitions;
extern func* func_list;
//#define DEBUG_MODE 1

void myDebug(const char *s) {

	#ifdef DEBUG_MODE
	printf(s);
	#endif

}


%}


%%

"&" {}
"scanf" {myDebug("SCANF\n"); return SCANF; }
"printf" {myDebug("PRINTF\n"); return PRINTF; }
"matrix" {myDebug("MATRIX\n");return MATRIX;}
";" {myDebug("SEMI_COLON\n");return SEMI_COLON; }
"newtype" {myDebug("NEWTYPE\n"); return NEWTYPE; }
"(" {myDebug("OP\n"); return OP;}
")" {myDebug("CP\n"); return CP;}
"record" {myDebug("RECORD\n"); return RECORD; }
"array" {myDebug("ARRAY\n"); return ARRAY; }
"integer" {myDebug("INTEGER\n"); yylval.str = strdup(yytext); return INTEGER; }
"boolean" {myDebug("BOOLEAN\n"); yylval.str = strdup(yytext); return BOOLEAN; }
"[" {myDebug("OSP\n"); return OSP; }
"]" {myDebug("CSP\n"); return CSP; }
"floating" {myDebug("FLOATING\n"); yylval.str = strdup(yytext);  return FLOATING; }
"char" {myDebug("CHAR\n"); yylval.str = strdup(yytext); return CHAR; }
"string" {myDebug("STRING\n"); yylval.str = strdup(yytext); return STRING_TYPE; }
"," {myDebug("COMMA\n"); return COMMA; }
"=" {myDebug("ASSIGN\n"); return ASSIGN; }
"-" {myDebug("MINUS\n"); return MINUS; }
"->" {myDebug("ARROW\n"); return ARROW; }
"||" {myDebug("OR\n"); return OR; }
"&&" {myDebug("AND\n");  return AND; }
"!" {myDebug("NOT\n");  return NOT; }
"==" {myDebug("EQUAL\n");  return EQUAL; }
"!=" {myDebug("NOTEQUAL\n"); return NOTEQUAL; }
"+" {myDebug("PLUS\n"); return PLUS; }
"*" {myDebug("MUL\n");  return MUL; }
"#" {myDebug("EXP\n"); return EXP; }
"/" {myDebug("DIV\n");  return DIV; }
"func" {myDebug("FUNC\n");  functionDefinitions = 1; change_environment();myDebug("Nuovo environment\n"); return FUNC; }
func[ ]+exec {int a = check_recursive_definitions(); if(a==0) { myDebug("Errore nelle definizioni ricorsive dei tipi\n"); exit(1); } myDebug("FUNC_EXEC\n"); change_environment(); myDebug("Nuovo environment\n"); return FUNC_EXEC; }
":" {myDebug("COLON\n");  return COLON; }
"begin" {myDebug("BEG\n"); return BEG; }
"end" {	
	myDebug("END\n"); 
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
	myDebug("//lexer.l : Pop environment\n");
	return END; 
	}
"return" {myDebug("RETURN\n"); return RETURN; }
"{" {myDebug("OGP\n"); return OGP; }
"}" {myDebug("CGP\n"); return CGP; }
"new" {myDebug("NEW\n"); return NEW; }
"if" {myDebug("IF\n"); return IF; }
"else" {myDebug("ELSE\n"); return ELSE; }
"loop" {myDebug("LOOP\n"); return LOOP; }
"free" {myDebug("FREE\n"); return FREE; }
">" {myDebug("GRT\n"); return GRT; }
"<" {myDebug("LST\n"); return LST; }
">=" {myDebug("GTE\n"); return GTE; }
"<=" {myDebug("LTE\n"); return LTE; }
"newvars" {myDebug("NEWVARS\n"); return NEWVARS; }
"then" {myDebug("THEN\n"); return THEN; }
"true" {myDebug("BOOLEAN_CONSTANT\n"); yylval.str = (char*) strdup(yytext); return BOOLEAN_CONSTANT; }
"false" {myDebug("BOOLEAN_CONSTANT\n"); yylval.str = (char*) strdup(yytext); return BOOLEAN_CONSTANT;}
[1-9][0-9]* {myDebug("INTEGER_CONSTANT\n"); yylval.intval = atoi(yytext); return INTEGER_CONSTANT; }
"'"[:alnum:]*"'"  {myDebug("CHARACTER_CONSTANT\n"); yylval.str = (char*) strdup(yytext); return CHARACTER_CONSTANT; }
\"(\\.|[^\\"])*\"  {myDebug("STRING\n"); yylval.str = (char*) strdup(yytext); return STRING; }
[0-9]*"."[0-9]* {myDebug("FLOATING_CONSTANT\n"); yylval.dval = atof(yytext); return FLOATING_CONSTANT; }
"overload" {myDebug("OVERLOAD\n"); change_environment(); myDebug("Nuovo environment\n");return OVERLOAD; }
[_a-zA-Z][_a-zA-Z0-9]{0,30} {myDebug("IDENTIFIER\n"); myDebug(yytext); yylval.id = (char*) strdup(yytext); return IDENTIFIER;}
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
