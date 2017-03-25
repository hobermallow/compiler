%{
#include "bison.tab.h"	
#include "type_definitions.h"
//dichiaro le variabili globali per la gesstione delle definizioni di funzione
extern int functionDefinitions;
extern func* func_list;

%}

%%

"matrix" {return MATRIX;}
";" {return SEMI_COLON; }
"newtype" {return NEWTYPE; }
"(" {return OP;}
")" {return CP;}
"record" {return RECORD; }
"array" {return ARRAY; }
"integer" {yylval.str = strdup(yytext); return INTEGER; }
"boolean" {yylval.str = strdup(yytext); return BOOLEAN; }
"[" {return OSP; }
"]" {return CSP; }
"floating" {yylval.str = strdup(yytext);  return FLOATING; }
"char" {yylval.str = strdup(yytext); return CHAR; }
"string" {yylval.str = strdup(yytext); return STRING_TYPE; }
"," {return COMMA; }
"=" {return ASSIGN; }
"-" {return MINUS; }
"->" {return ARROW; }
"||" { return OR; }
"&&" { return AND; }
"!" { return NOT; }
"==" { return EQUAL; }
"!=" {return NOTEQUAL; }
"+" {return PLUS; }
"*" { return MUL; }
"#" {return EXP; }
"/" { return DIV; }
"func" { functionDefinitions = 1; change_environment();printf("Nuovo environment\n"); return FUNC; }
func[ ]+exec {if(check_recursive_definitions()== 1) {change_environment(); printf("Nuovo environment\n"); return FUNC_EXEC; } else { printf("Errore nelle definizioni ricorsive\n"); exit(1); }}
":" { return COLON; }
"begin" {return BEG; }
"end" {pop_environment();printf("Pop environment\n"); return END; }
"return" {return RETURN; }
"{" {return OGP; }
"}" {return CGP; }
"new" {return NEW; }
"if" {return IF; }
"else" {return ELSE; }
"loop" {return LOOP; }
"free" {return FREE; }
">" {return GRT; }
"<" {return LST; }
">=" {return GTE; }
"<=" {return LTE; }
"newvars" {return NEWVARS; }
"then" {return THEN; }
"true" {yylval.str = (char*) strdup(yytext); return BOOLEAN_CONSTANT; }
"false" {yylval.str = (char*) strdup(yytext); return BOOLEAN_CONSTANT;}
[1-9][0-9]* {yylval.intval = atoi(yytext); return INTEGER_CONSTANT; }
"'"[:alnum:]*"'"  {yylval.str = (char*) strdup(yytext); return CHARACTER_CONSTANT; }
"\""[:alnum:]*"\""  {yylval.str = (char*) strdup(yytext); return STRING; }
[0-9]*"."[0-9]* {yylval.dval = atof(yytext); return FLOATING_CONSTANT; }
"overload" {change_environment(); printf("Nuovo environment\n");return OVERLOAD; }
[_a-zA-Z][_a-zA-Z0-9]{0,30} { yylval.id = (char*) strdup(yytext); return IDENTIFIER;}
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
