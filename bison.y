%{
	#include <stdio.h>
	#include <stdlib.h>
	#include "SM.h"
	#include <string.h>
%}
%union {
	int intval;
	double dval;
	char* str;
	char* id;
	struct param* par;
	struct value* val;
	struct sym_rec* symrec;
}

%token MATRIX
%token SEMI_COLON
%token NEWTYPE
%token <id> IDENTIFIER
%token OP
%token CP
%token RECORD
%token ARRAY
%token OSP
%token CSP
%token <str> STRING
%token COMMA
%token ASSIGN
%token MINUS
%token ARROW
%token OR
%token AND
%token NOT
%token EQUAL
%token NOTEQUAL
%token PLUS
%token MUL
%token EXP
%token DIV
%token FUNC
%token FUNC_EXEC /*fare in lexer */
%token COLON
%token BEG
%token END
%token RETURN
%token OGP
%token CGP
%token NEW
%token IF
%token ELSE
%token LOOP
%token FREE
%token GRT
%token LST
%token GTE
%token LTE
%token NEWVARS
%token THEN
%token <str> INTEGER FLOATING BOOLEAN STRING_TYPE CHAR
%token <intval> INTEGER_CONSTANT
%token <str> CHARACTER_CONSTANT
%token <dval> FLOATING_CONSTANT
%token OVERLOAD
%token EOL
%token EOF_TOKEN
%type <str> type
%type <str> basetype
%type <par> param parlist params var varlist field fieldlist
%type <val> constant primary_expression expression conditional_expression logical_or_expression logical_and_expression logical_not_expression exclusive_or_expression and_expression equality_expression relational_expression shift_expression additive_expression multiplicative_expression exp_expression cast_expression unary_expression postfix_expression exprlist exprlist_temp arrayexpr
%type <symrec> typebuilder

%start S

%%

/* grammar starting symbol */
S : declist deffunclist overloads varlistdecl main EOF_TOKEN  	{ printf("parsato !\n"); return 0; }
	;
declist : 
	/*empty */
	| declist decl
	;


decl : NEWTYPE IDENTIFIER typebuilder SEMI_COLON {
						//recupero il sym_rec
						sym_rec* sym = $3;
						//debbo aggiungere solamente il nome
						sym->text = strdup($2);	
						//aggiungo il simbolo alla symbol table
						insert_sym_rec(sym);
						}
							 
	;
typebuilder : RECORD OP fieldlist field CP {
						//unisco i field
						$4->next = $3;
						//creo il nuovo record
						sym_rec* temp = (sym_rec*) malloc(sizeof(sym_rec));
						//setto i parametri
						temp->par_list = $4;
						//setto il tipo
						temp->type = "record";
						//imposto current_param
						temp->current_param = temp->par_list;
						//ritorno il sym_rec
						$$ = temp;
					}
	| MATRIX OP basetype COMMA expression COMMA expression CP {
						//controllo che il tipo delle espressioni sia intero
						check_is_integer($5);
						check_is_integer($7);
						//creo il nuovo tipo
						sym_rec* temp = (sym_rec*) malloc(sizeof(sym_rec));
						temp->type = "matrix";
						//creo due nuovi parametri
						param *temp_1, *temp_2;
						temp_1 = (param*) malloc(sizeof(param));
						temp_2 = (param*) malloc(sizeof(param));
						//copio i valori nei due parametri
						copy_val_in_param(temp_1, $5);
						copy_val_in_param(temp_2, $7);
						//unisco i parametri
						temp_2->next = temp_1;
						//salvo i parametri
						temp->par_list = temp_2;
						//salvo il tipo della matrice
						temp->param_type = strdup($3);
						//setto current_param
						temp->current_param = temp->par_list;
						//ritorno il sym_rec
						$$ = temp;
					}

	| ARRAY OP type COMMA arrayexpr expression CP {
							//creo il nuovo elemento per la symbol table
							sym_rec* rec = malloc (sizeof(sym_rec));
							rec->type = "array";
							//per ciacun valore, debbo creare il parametro
							value* temp;
							param* parlist = (param*) malloc(sizeof(param));
							param* parlisttemp;
							//creo il primo parametro
							copy_val_in_param(parlist, $6);
							//segnaposto
							parlisttemp = parlist;
							for(temp = $5; temp != 0; temp = temp->next) {
								//creo il parametro
								param* tem = malloc(sizeof(param));
								copy_val_in_param(tem, temp);
								//aggiungo il parametro alla lista
								parlisttemp->next = tem;
								parlisttemp = tem;
							}
							//aggiungo la lista al simbolo
							rec->par_list = parlist;
							//setto current_param
							rec->current_param = rec->par_list;
							rec->param_type = strdup($3);
							$$ = rec;
							}
	;

arrayexpr :	
	 /* empty */ { $$ = 0; }
	| arrayexpr expression COMMA {
					//aggiungo il valore alla lista
					$2->next = $1;
					$$ = $2;
				} 
	;

fieldlist : 
	/* empty */	{ $$ = 0; }
	| fieldlist field COMMA {
					//recupero il parametro
					$2->next = $1;
					$$ = $2;
				}
	;
 
field : type IDENTIFIER {
				//creo il parametro
				param* temp = malloc(sizeof(param));	
				temp->type = strdup($1);
				temp->name = strdup($2);
			}
	; 

type : basetype { $$ = $1; }
	| IDENTIFIER { $$ = $1; }
	;

basetype : INTEGER  { $$ = $1; }
	| BOOLEAN { $$ = $1; }
	| FLOATING { $$ = $1; } 
	| CHAR { $$ = $1; }
	| STRING_TYPE { $$ = $1; }
	;

expression : conditional_expression { $$ = $1; }
	;

conditional_expression : logical_or_expression  { $$ = $1; }
	;

logical_or_expression : logical_and_expression { $$ = $1; }
	| logical_or_expression OR logical_and_expression { value* temp = (value*) malloc(sizeof(value));
							    temp->val = (int*) malloc(sizeof(int));
							    *((int*)(temp->val)) = *((int*)($1->val)) || *((int*)($3->val));
							    $$ = temp;
							  }
	;

logical_and_expression : logical_not_expression  { $$ = $1; }
	| logical_and_expression AND logical_not_expression { value* temp = (value*) malloc(sizeof(value));
							      temp->val = (int*) malloc(sizeof(int));
								*((int*)(temp->val)) = *((int*)($1->val)) && *((int*)($3->val));
								$$ = temp;
							    }
	;

logical_not_expression : exclusive_or_expression { $$ = $1; }
	| NOT logical_not_expression { value* temp = (value*) malloc(sizeof(value));
				       temp->val = (int*) malloc(sizeof(int));
				       *((int*)(temp->val)) = ! *((int*)($2->val));
					$$ = temp;
				    }
	;

exclusive_or_expression : and_expression { $$ = $1; }
	;

and_expression : equality_expression { $$ = $1; }
	;

equality_expression : relational_expression { $$ = $1; }
	| equality_expression EQUAL relational_expression { value *temp = (value*) malloc(sizeof(value)); check_type($1, $3); temp->type = "boolean"; temp->val = (int*)malloc(sizeof(int)); *((int*)(temp->val)) = check_equal($1, $3);  $$ = temp; }
	| equality_expression NOTEQUAL relational_expression   { value *temp = (value*) malloc(sizeof(value)); check_type($1, $3); temp->type = "boolean"; temp->val = (int*) malloc(sizeof(int)); *((int*)(temp->val)) = check_equal($1,$3); $$ = temp; }
	;

relational_expression : shift_expression { $$ = $1; }
	;

shift_expression : additive_expression { $$ = $1; }
	;

additive_expression : multiplicative_expression { $$ = $1; }
	| additive_expression PLUS multiplicative_expression { value* temp = (value*) malloc(sizeof(value)); check_type($1, $3); temp->type = strdup($1->type); add_base_type(0, $1, $3, temp); $$ = temp; }
	| additive_expression MINUS multiplicative_expression   { value* temp = (value*) malloc(sizeof(value)); check_type($1, $3); temp->type = strdup($1->type); add_base_type(1, $1, $3, temp); $$ = temp; }
	;
multiplicative_expression : exp_expression { $$ = $1; }
	| multiplicative_expression MUL exp_expression   { value* temp = (value*) malloc(sizeof(value)); check_type($1, $3); temp->type = strdup($1->type); mul_base_type(0, $1, $3, temp); $$ = temp; }
	| multiplicative_expression DIV exp_expression    { value* temp = (value*) malloc(sizeof(value)); check_type($1, $3); temp->type = strdup($1->type); mul_base_type(1, $1, $3, temp); $$ = temp; }
	;

exp_expression : cast_expression { $$ = $1; }
	| exp_expression EXP cast_expression { value* temp = (value*) malloc(sizeof(value)); temp->type = strdup($3->type); exp_base_type($1, temp); $$ = temp; }
	;

cast_expression : unary_expression { $$ = $1; }
	| FLOATING OP cast_expression CP { check_is_integer($3); value* temp = (value*) malloc(sizeof(value)); temp->type = "floating"; temp->val = (double*) malloc(sizeof(double)); *((double*)(temp->val)) = (double)(*((int*)($3->val))); $$ = temp; }
	;


assignment_operator : ASSIGN
	;

unary_operator : MINUS
	;
	
unary_expression : postfix_expression { $$ = $1; 
					reset_current_param($1);
					}
	| unary_operator cast_expression { change_sign($2); $$ = $2; }
	;

postfix_expression : primary_expression { $$ = $1; }
	| postfix_expression OSP expression CSP {
						//debbo controllare che l'espressione inserita sia compatibile con le espressioni inserite
						//in primis, essendo indice di array, controllo che expression sia integer
						check_is_integer($3);
						//in secundis, controllo che il valore dell'espressione sia compreso nel limite dell'array
						check_array_arguments($1, $3);
						//ritorno $1
						$$ = $1;
						}
	| postfix_expression OSP expression COMMA expression CSP
	| postfix_expression OP exprlist CP {
						//debbo controllare che i parametri inseriti corrispondano a quelli dichiarati nella func
						//richiamo una routine che prende in input il nome della funzione e la lista di argomenti
						check_function_arguments($1, $3);
						//ritorno il value corrispondente alla funzione, che cosi ho il tipo
						$$ = $1;
						}
	| postfix_expression ARROW IDENTIFIER
	;

exprlist : 
	/* empty rule */ { $$ = 0; }
	| exprlist_temp expression {
					//aggiungo a $2 il valore di $1 come next
					$2->next = $1;
					//ritorno $2
					$$ = $2;
				   }
	;
exprlist_temp : 
	/* empty */ { $$ = 0; }
	| exprlist_temp expression COMMA {
					$2->next = $1;
					$$ = $2;
				}
	;

primary_expression : IDENTIFIER { //controllo se sia stato dichiarato l'identificatore
				sym_rec* rec = get_sym_rec($1);
				if(rec == 0) {
					printf("Identificarore %s non trovato\n", $1);
					exit(1);
				}
				else {
					printf("Record %s trovato\n", $1);
					//creo il value 
					value* temp = (value*) malloc(sizeof(value));
					//recupero il tipo dalla dichiarazione
					temp->type = strdup(rec->type);
					//recuper il nome
					temp->name = strdup(rec->text); 
					//recuper il valore
					temp->val = rec->val;
					//ritorno il valore
					$$ = temp;
				}
				}
	| constant { $$ = $1; }
	| STRING { //creo la stringa
		value* temp = (value*) malloc(sizeof(value));
		temp->val = strdup($1);
		temp->type = "string";
		$$ = temp;
		}
	| OP expression CP { $$ = $2; }
	;

constant : INTEGER_CONSTANT { value* temp = (value*) malloc(sizeof(value)); temp->val = malloc(sizeof(int)); *((int*)(temp->val)) = $1; temp->type = "integer";  $$ = temp; }
	| CHARACTER_CONSTANT { value* temp = (value*) malloc(sizeof(value)); temp->val = strdup($1); temp->type = "character"; $$ = temp; }
	| FLOATING_CONSTANT { value* temp = (value*) malloc(sizeof(value)); temp->val = malloc(sizeof(double));*((double*)(temp->val)) = $1; temp->type = "floating"; $$ = temp; }
	;


varlistdecl : 
	/* empty */
	| varlistdecl vardecl 
	;

vardecl : NEWVARS type varlist var  SEMI_COLON  {
						//per ciascun paramentro aggiungo simbolo
						sym_rec* symbol;
						param* temp;
						for(temp = $3; temp != 0; temp = temp->next) {
							symbol = (sym_rec*) malloc(sizeof(sym_rec));
							symbol->text = strdup(temp->name);
							symbol->type = strdup($2);
							//inserisco il simbolo nella symbol table
							insert_sym_rec(symbol);
							printf("Inserisco simbolo %s di tipo %s\n", symbol->text, symbol->type);
						}
						//inserico val
						symbol = (sym_rec*) malloc(sizeof(sym_rec));
						symbol->text = strdup($4->name);
						symbol->type = strdup($2);
						initialize_value(symbol);
						insert_sym_rec(symbol);	
						printf("Inserisco simbolo %s di tipo %s\n", symbol->text, symbol->type);
						}
	;

var : IDENTIFIER {
		//creo la lista di variabili come parametri
		param* temp = (param*) malloc(sizeof(param));
		temp->name = strdup($1);
		$$ = temp;
		}
	;

varlist :
	/* empty */ { $$ = 0; }
	| varlist var COMMA {
				//aggiungo la lista a var
				$2->next = $1;
				$$ = $2;
			    }
	;

deffunclist :
	/* empty */
	| deffunclist deffunc 
	;

deffunc : FUNC IDENTIFIER OP params CP COLON type block { //inserisco nella symbol table il simbolo corrispondente alla funzione
							sym_rec *func = (sym_rec*) malloc(sizeof(sym_rec));
							//inserisco nome della funzione
							func->text = strdup($2);
							//inserisco il tipo di ritorno della funzione
							func->type = strdup($7);
							//inserisco i parametri
							func->par_list = $4;
							//inserisco il simbolo appena creato nella symbol table
							insert_sym_rec(func);
							printf("Inserito simbolo per la funzione %s\n", func->text);
							}

							
	;

main : FUNC_EXEC OP params CP COLON type block  { //inserisco nella symbol table il simbolo corrispondente alla funzione
							sym_rec *func = (sym_rec*) malloc(sizeof(sym_rec));
							//inserisco nome della funzione
							func->text = "exec";
							//inserisco il tipo di ritorno della funzione
							func->type = strdup($6);
							//inserisco i parametri
							func->par_list = $3;
							//inserisco il simbolo appena creato nella symbol table
							insert_sym_rec(func);
							printf("Inserito simbolo per la funzione %s\n", func->text);
							}

	;

params : 
	/* empty */ { $$ = 0; }
	| parlist param {
			$2->next = $1;
			$$ = $2;
			//stampo tutti i parametri
			param* temp;
			}
	;

parlist : 
	/* empty */ { $$ = 0; }
	| parlist param COMMA {//provo cosi. salvo il valore di ritorno di parlist come next element di param
				$2->next = $1;
				//ritorno la lista completa
				$$ = $2; 
				}
	;

param : type IDENTIFIER {//prova di aggiunta di simbolo
			//alloco spazio per il parametro
			param* temp = (param*) malloc(sizeof(param));
			//associo i valori
			temp->name = strdup($2);
			temp->type = strdup($1);
			//ritorno il parametro
			$$ = temp;
			//inserisco il simbolo nella symbol table
			sym_rec* rec = (sym_rec*)malloc(sizeof(sym_rec));
			rec->text = strdup($2);
			rec->type = strdup($1);
			initialize_value(rec);
			insert_sym_rec(rec);
			printf("Inserito simbolo %s di tipo %s\n", rec->text, rec->type);
			}
	;

block : BEG body END 
	;

body : declist varlistdecl stmts 
	;

stmts : 
	/* empty */
	| stmts stmt 
	;

stmt :	assignment_statement
	| block
	| selection_statement
	| iteration_statement
	| object_statement
	| jump_statement
	;

jump_statement : RETURN jump_temp SEMI_COLON
	;

jump_temp :
	/* empty */
	| expression
	;	


selection_statement : IF OP expression CP BEG stmts END
	| IF OP expression CP BEG stmts END ELSE BEG stmts END 
	;

iteration_statement : LOOP OP expression CP BEG stmts END
	;

assignment_statement : unary_expression assignment_operator expression SEMI_COLON { check_type($1,$3); copy_val($1,$3); }
	| expression SEMI_COLON
	/* eliminata statements fatta da solo SEMI_COLON */
	;

object_statement : FREE OP IDENTIFIER CP SEMI_COLON
	| unary_expression ASSIGN  NEW OP IDENTIFIER CP SEMI_COLON
	;

overloads :
	/*empty */
	| overloads overload 
	;

overload : OVERLOAD OP overloadable_operands COMMA IDENTIFIER CP BEG stmts END
	;

overloadable_operands : PLUS
	| MINUS
	| MUL
	| DIV
	| EXP
	| LST
	| GRT
	| LTE
	| GTE
	| EQUAL
	| NOTEQUAL
	;
 


%%

void yyerror (char const *s) {
	printf("errore \n");
}

main(int argc, char* argv[]) {
	//file per la lettura da sorgente
        FILE* f;
	//variabile corrispondente al buffer del lexer
	extern FILE* yyin;
	//inizializzo la symbol table
	extern sym_table* top ; 
	top = (sym_table*) malloc(sizeof(sym_table));
        if(argc == 2) {
                f = fopen(argv[1], "r");
                yyin = f;
        }
        yyparse();
	//DEBUG, STAMPO TUTTI I SIMBOLI PRESENTI NELLA SYMBOL TABLE 
	sym_table* table;
	sym_rec* rec;
	for(table = top; table != 0; table = table->next) {
		for(rec = table->entries; rec != 0; rec = rec->next) {
			if(rec->text != 0) {
				printf("Lessema corrispondente al token: %s\n", rec->text);
				printf("Tipo del lessema %s\n", rec->type);
			}
		}
	}
}

