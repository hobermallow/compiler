%{
	#include <stdio.h>
	#include <stdlib.h>
	#include <string.h>
	#include "SM.h"

	extern int functionDefinitions;
	extern func* func_list;
	extern func* func_list_total;

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
%token <str> PRINTF
%token <str> SCANF
%token SEMI_COLON
%token NEWTYPE
%token <id> IDENTIFIER
%token <str> OP
%token <str> CP
%token <str> RECORD
%token <str> ARRAY
%token OSP
%token CSP
%token <str> STRING
%token <str> COMMA
%token ASSIGN
%token <str> MINUS
%token ARROW
%token OR
%token AND
%token NOT
%token <str> EQUAL
%token <str> NOTEQUAL
%token <str> PLUS
%token <str> MUL
%token <str> EXP
%token <str> DIV
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
%token <str> GRT
%token <str> LST
%token <str> GTE
%token <str> LTE
%token NEWVARS
%token THEN
%token <str> BOOLEAN_CONSTANT
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
%type <str> overloadable_operands

%start S

%%

/* grammar starting symbol */
S : declist_check deffunclist_check overloads varlistdecl main EOF_TOKEN  	{ printf("parsato !\n"); return 0; }
	;

declist_check : declist {	
				printf("//bison.y: all'inizio della declist_check\n");
				int a = check_recursive_definitions();
				if( a== 0) {
					printf("//bison.y: errore nella definizione delle funzioni ricorsive\n");
					exit(1);
				}
			}
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
						//debug
						//print_array_params(sym);
						//finisco di creare e stampo il codice associato alla dichiarazione del nuovo tipo
						char *s = calloc(1, sizeof(char)); 
						strcat(s, "typedef ");
						strcat(s, $3->code);
						printf("//bison.y: madonna ladra %s\n", $3->code);
						strcat(s, " ");
						printf("//bison.y: codice del secondo field %s\n", $2);
						strcat(s, $2);
						strcat(s, " ;\n");
						//$3->code = prependString("newtype ", prependString($2, prependString($3->code, " ;\n")));
						printf("//bison.y: codice del typebuilder\n");
						printf("%s \n",s );
						printf("//bison.y: alla fine della dichiarazione del nuovo tipo \n");
						}

	;
typebuilder : RECORD OP fieldlist field CP {    printf("//bison.y: record: %s %s %s %s %s\n", $1, $2, $3, $4, $5);
						//unisco i field
						$4->next = $3;
						printf("//bison.y: dopo la next\n");
						//creo il nuovo record
						sym_rec* temp = (sym_rec*) malloc(sizeof(sym_rec));
						printf("//bison.y: dopo il nuovo record\n");
						//setto i parametri
						temp->par_list = $4;
						printf("//bison.y: dopo par_list\n");
						//setto il tipo
						temp->type = "record";
						printf("//bison.y: dopo set del tipo \n");
						//imposto current_param
						temp->current_param = temp->par_list;
						printf("//bison.y: dopo current param\n");
						//associo il codice
						char* s = calloc(1, sizeof(char));
						if($3 == 0) {
							strcat(s, "struct { ");
							printf("//bison.y: primo strcat\n");
							strcat( s, $4->code);
							strcat( s, "\n}\n");
							temp->code = s;

						}else {
							strcat(s, "struct { ");
							strcat(s, $3->code);
							strcat(s, "\n");
							strcat(s, $4->code);
							strcat(s, "\n}\n");
							temp->code = s;

						}
						printf("//bison.y: dopo l'if \n");
						//ritorno il sym_rec
						$$ = temp;
						printf("//bison.y: codice del typebuilder del record %s\n", $$->code);

					}
	| MATRIX OP basetype COMMA expression COMMA expression CP {
						//controllo che il tipo delle espressioni sia intero
						check_is_integer($5);
						check_is_integer($7);
						//controllo che il tipo degli elementi della matrice sia intero o floating
						if(strcmp($3, "integer") != 0 && strcmp($3, "floating") != 0 ) {
							printf("Tipo selezionato per i campi della matrice non valido \n");
							exit(1);
						}
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
						temp_1->next = temp_2;
						//salvo i parametri
						temp->par_list = temp_1;
						//salvo il tipo della matrice
						temp->param_type = strdup($3);
						//setto current_param
						temp->current_param = temp->par_list;
						//aggiugo il codice al valore di ritorno
						char s = "matrix ";
						strcat(s, "(");
						strcat(s, $3);
						strcat(s, ", ");
						strcat(s, $5->code);
						strcat(s, ", ");
						strcat(s, $7->code);
						strcat(s, " )");
						temp->code = s;
						//temp->code = prependString("matrix ", prependString(" ( ", prependString($3, prependString(", ", prependString($5->code, prependString(", ", prependString($7->code, " )"))))) ));
						//ritorno il sym_rec
						$$ = temp;
					}

	| ARRAY OP type COMMA arrayexpr expression CP { 
							printf("dentro la definizione dell'array\n");
							//creo il nuovo elemento per la symbol table
							sym_rec* rec = malloc (sizeof(sym_rec));
							rec->type = "array";
							//per ciacun valore, debbo creare il parametro
							value* temp;
							param* parlist = (param*) malloc(sizeof(param));
							param* parlisttemp;
							//creo il primo parametro
							copy_val_in_param(parlist, $6);
							//assegno anche il tipo del parametro
							//serve per controllo di definizioni ricorsive dei tipi
							parlist->type = strdup($3);
							//segnaposto
							parlisttemp = parlist;
							for(temp = $5; temp != 0; temp = temp->next) {
								//creo il parametro
								param* tem = malloc(sizeof(param));
								copy_val_in_param(tem, temp);
								tem->type = strdup($3);
								//aggiungo il parametro alla lista
								parlisttemp->next = tem;
								parlisttemp = tem;
							}
							//parlisttemp e' alias di parlist
							parlisttemp->next = 0;
							//aggiungo la lista al simbolo
							rec->par_list = parlist;
							//inverto la lista
							//param *x, *y, *z;
							//x = 0;
							//y = rec->par_list;
							//while(y != 0) {
							//	z = y->next;
							//	y->next = x;
							//	x = y;
							//	y = z;
							//}
							//rec->par_list= x;
							//setto current_param
							INVERT_PARAM_LIST(rec->par_list)
							rec->current_param = rec->par_list;
							rec->param_type = strdup($3);
							//ritorno il codice associato al valore di ritorno
							if($5 == 0) {
								char *s = calloc(1, sizeof(char));
								strcat(s, " array ");
								strcat(s, "(");
								strcat(s, $3);
								strcat(s, " , ");
								strcat(s, $6->code);
								strcat(s, " ) ");
								rec->code = s; 
								//rec->code = prependString(" array ", prependString("(", prependString($3, prependString(" , ", prependString($6->code, " )")))));
							}
							else {
								char *s = calloc(1, sizeof(char));
								strcat(s, " array ");
								strcat(s, "(");
								strcat(s, $3);
								strcat(s, " , ");
								strcat(s, $5->code);
								strcat(s, $6->code);
								strcat(s, " ) ");
								rec->code = s; 
								//rec->code = prependString(" array ",  prependString("(", prependString($3, prependString(", ", prependString($5->code, prependString($6->code, ")"))))));
							}
							$$ = rec;
							//print_array_params(rec);
							}
	;

arrayexpr :
	 /* empty */ { $$ = 0; }
	| arrayexpr expression COMMA {
					printf("inizio arrayexpr \n");
					//aggiungo il valore alla lista
					$2->next = $1;
					printf("dopo next\n");
					//associo il codice al valore di ritorno
					if($1 == 0) {
						char *s = calloc(1, sizeof(char));
						strcat(s, $2->code);
						strcat(s, ", ");
						$2->code = s;
						//$2->code = prependString(" ", prependString($2->code, ", "));
					}
					else {
						char *s = calloc(1, sizeof(char));
						strcat(s, $1->code);
						strcat(s, $2->code);
						strcat(s, ", ");
						$2->code = s;	
						//$2->code = prependString($1->code, prependString($2->code, ", "));
					}
					$$ = $2;
					printf("fine arrayexpr\n");
				}
	;

fieldlist :
	/* empty */	{ $$ = 0; }
	| fieldlist field COMMA {
					//recupero il parametro
					$2->next = $1;
					//associo il codice al valore di ritorno
					if($1 == 0) {
						char *s = calloc(1, sizeof(char));
						strcat(s, $2->code);
						$2->code = s;
						//$2->code = prependString(" ", prependString($2->code, ", "));
					}
					else {
						char *s = calloc(1, sizeof(char));
						strcat(s, $1->code);
						strcat(s, $2->code);
						$2->code = s;
						//$2->code = prependString($1->code, prependString($2->code, ", "));
					}
					$$ = $2;
				}
	;

field : type IDENTIFIER {
				//creo il parametro
				param* temp = malloc(sizeof(param));
				temp->type = strdup($1);
				temp->name = strdup($2);
				char *s = malloc(sizeof(char));
				strcat(s, $1);
				strcat(s, " ");
				strcat(s, $2);
				strcat(s, " ;\n");
				temp->code = s;
				//temp->code = prependString($1, $2);
				$$ = temp;
			}
	;

type : basetype {
									$$ = $1;
									}
	| IDENTIFIER {							//printf("%s\n", $1);
									$$ = $1;
									}
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

logical_or_expression : logical_and_expression {
																								$$ = $1;
																								}
	| logical_or_expression OR logical_and_expression {
																											value* temp = (value*) malloc(sizeof(value));
							    																		temp->val = (int*) malloc(sizeof(int));
							    																		*((int*)(temp->val)) = *((int*)($1->val)) || *((int*)($3->val));
								char *s = calloc(1, sizeof(char));
								strcat(s, $1->code);
								strcat(s, "||");
								strcat(s, $3->code);
								temp->code = s;
																											//temp->code = prependString($1->code, prependString("||", $3->code));
																											$$ = temp;
							  																		}
	;

logical_and_expression : logical_not_expression  {
																										$$ = $1;
																									}
	| logical_and_expression AND logical_not_expression {
																												value* temp = (value*) malloc(sizeof(value));
							      																		temp->val = (int*) malloc(sizeof(int));
																												*((int*)(temp->val)) = *((int*)($1->val)) && *((int*)($3->val));
									char *s = calloc(1, sizeof(char));
									strcat(s, $1->code);
									strcat(s, "&&");
									strcat(s, $3->code);
									temp->code = s;
																												//temp->code = prependString($1->code, prependString("&&", $3->code));
																												$$ = temp;
							    																		}
	;

logical_not_expression : exclusive_or_expression {
																									$$ = $1;
																									}
	| NOT logical_not_expression {
					value* temp = (value*) malloc(sizeof(value));
					temp->val = (int*) malloc(sizeof(int));
					*((int*)(temp->val)) = ! *((int*)($2->val));
					char *s = calloc(1, sizeof(char));
					strcat(s, "!");
					strcat(s, $2->code);
					temp->code = s;
					//temp->code = prependString("!", $2->code);
					$$ = temp;
				}
	;

exclusive_or_expression : and_expression { $$ = $1; }
	;

and_expression : equality_expression { $$ = $1; }
	;

equality_expression : relational_expression { $$ = $1; }
	| equality_expression EQUAL relational_expression {
								value *temp = (value*) malloc(sizeof(value));
								printf("tipo di $1 %s tipo di $3 %s \n", $1->type, $3->type);
								if(strcmp($1->type, "unidentified") != 0 && strcmp($3->type, "unidentified") != 0)
									check_type($1, $3);
								temp->type = "boolean";
								//temp->val = (int*)malloc(sizeof(int));
								//*((int*)(temp->val)) = check_equal($1, $3);
								char *s = calloc(1, sizeof(char));
								strcat(s, $1->code);
								strcat(s, "==");
								strcat(s, $3->code);
								temp->code = s;
								//temp->code = prependString($1->code, prependString("==", $3->code));
								$$ = temp;
							 }
	| equality_expression NOTEQUAL relational_expression   {
								value *temp = (value*) malloc(sizeof(value));
								if(strcmp($1->type, "unidentified") != 0 && strcmp($3->type, "unidentified") != 0)
									check_type($1, $3);
								temp->type = "boolean";
								//temp->val = (int*)malloc(sizeof(int));
								//*((int*)(temp->val)) = check_equal($1, $3);
								//aggiungo il codice al valore di ritorno
								char *s = calloc(1, sizeof(char));
								strcat(s, $1->code);
								strcat(s, "!=");
								strcat(s, $3->code);
								temp->code =  s;
								//temp->code = prependString($1->code, prependString("!=", $3->code));
							 	$$ = temp;
							 }

	;

relational_expression : shift_expression { $$ = $1; }
	;

shift_expression : additive_expression { $$ = $1; }
	;

additive_expression : multiplicative_expression { $$ = $1; }
	| additive_expression PLUS multiplicative_expression {																				
								value* temp = (value*) malloc(sizeof(value));
																										if(strcmp($1->type, "unidentified") != 0 && strcmp($3->type, "unidentified") != 0) {										
									check_type($1, $3);
								}
																													if(strcmp($3->type, "unidentified") == 0) {
																														temp->type = strdup($1->type);
										}
																													else {
																														temp->type = strdup($3->type);
										}
																													//add_base_type(0, $1, $3, temp);
																													//aggiungo il codice al valore di ritorno
										char *s = calloc(1, sizeof(char));
										strcat(s, $1->code);
										strcat(s, "+");
										strcat(s, $3->code);
										temp->code = s;
																													//temp->code = prependString($1->code, prependString("+", $3->code));
																													$$ = temp;
																													}
	| additive_expression MINUS multiplicative_expression   {
																														value* temp = (value*) malloc(sizeof(value));
																														if(strcmp($1->type, "unidentified") != 0 && strcmp($3->type, "unidentified") != 0)
																															check_type($1, $3);
																														if(strcmp($3->type, "unidentified") == 0)
																															temp->type = strdup($1->type);
																														else
																															temp->type = strdup($3->type);
																														//add_base_type(0, $1, $3, temp);
											 char *s = calloc(1, sizeof(char));
											 strcat(s, $1->code);
											 strcat(s, "-");
											 strcat(s, $3->code);
											 temp->code = s;
																														//temp->code = prependString($1->code, prependString("-", $3->code));
																														$$ = temp;
																														}

	;
multiplicative_expression : exp_expression { $$ = $1; }
	| multiplicative_expression MUL exp_expression   {
																											value* temp = (value*) malloc(sizeof(value));
																											if(strcmp($1->type, "unidentified") != 0 && strcmp($3->type, "unidentified") != 0)
																												check_type($1, $3);
																											if(strcmp($3->type, "unidentified") == 0)
																												temp->type = strdup($1->type);
																											else
																												temp->type = strdup($3->type);
																											//mul_base_type(0, $1, $3, temp);
																											// associo il codice
								 char *s = calloc(1, sizeof(char));
								 strcat(s, $1->code);
								 strcat(s, "*");
								 strcat(s, $3->code);
								 temp->code = s;
																											//temp->code = prependString($1->code, prependString("*", $3->code));
																											$$ = temp;
																											}

	| multiplicative_expression DIV exp_expression    {
																											value* temp = (value*) malloc(sizeof(value));
																											if(strcmp($1->type, "unidentified") != 0 && strcmp($3->type, "unidentified") != 0)
																												check_type($1, $3);
																											if(strcmp($3->type, "unidentified") == 0)
																												temp->type = strdup($1->type);
																											else
																												temp->type = strdup($3->type);
																											//mul_base_type(1, $1, $3, temp);
																											//associo il codice
								 char *s = calloc(1, sizeof(char));
								 strcat(s, $1->code);
								 strcat(s, "/");
								 strcat(s, $3->code);
								 temp->code = s;
																											//temp->code = prependString($1->code, prependString("/", $3->code));
																											$$ = temp;
																											}

	;

exp_expression : cast_expression { $$ = $1; }
	| exp_expression EXP cast_expression {
																					value* temp = (value*) malloc(sizeof(value));
																					temp->type = strdup($3->type);
		  char *s = calloc(1, sizeof(char));
		  strcat(s, $1->code);
		  strcat(s, "#");
		  strcat(s, $3->code);
		  temp->code = s;
																					//temp->code = prependString($1->code, prependString("#", $3->code));
																					$$ = temp;
																					}
	;

cast_expression : unary_expression { $$ = $1; }
	| FLOATING OP cast_expression CP {
																		check_is_integer($3);
																		value* temp = (value*) malloc(sizeof(value));
																		temp->type = "floating";
																		temp->val = (double*) malloc(sizeof(double));
																		*((double*)(temp->val)) = (double)(*((int*)($3->val)));
																		//associo il codice relativo alla espressione di cast
			char *s = calloc(1, sizeof(char));
			strcat(s, "floating");
			strcat(s, "(");
			strcat(s, $3->code);
			strcat(s, ")");
			temp->code = s;
																		//temp->code = prependString("floating", prependString("(", prependString($3->code, ")")));
																		$$ = temp; }
	;


assignment_operator : ASSIGN
	;

unary_operator : MINUS
	;

unary_expression : postfix_expression {
					 $$ = $1;
					reset_current_param($1);
					}
	| unary_operator cast_expression {
																		change_sign($2);
																		//associo al valore di ritorno il codice relativo
				char *s = calloc(1, sizeof(char));
				strcat(s, "-");
				strcat(s, $2->code);
				$2->code = s;
					//													$2->code = prependString("-", $2->code);
																		$$ = $2;
																		}
	;

postfix_expression : primary_expression {
 					//controllo se sia stato dichiarato l'identificatore
					 $$ = $1;
					 }
	| postfix_expression OSP expression CSP {
						//debbo controllare che l'espressione inserita sia compatibile con le espressioni inserite
						//in primis, essendo indice di array, controllo che expression sia integer
						check_is_integer($3);
						//in secundis, controllo che il valore dell'espressione sia compreso nel limite dell'array
						//print_array_params(get_sym_rec($1->name));
						//siccome non voglio cambiare la funzione check , creo un nuovo val...
						//lebensraum
						value* val = (value*)malloc(sizeof(value));
						val->name = strdup($1->name);
						val->type = strdup($1->custom_type);
						check_array_arguments(val, $3);
						//controllo che sia stata allocata memoria per l'array
						check_mem_alloc($1);
						//sto dereferenziando array , quindi modifico il tipo
						if(is_base_type($1->type) == 0) {
							//recupero il record corrispondente al tipo dell'array
							sym_rec* type = (sym_rec*)get_sym_rec($1->type);
							$1->type = strdup(type->param_type);
							//associo alla chiamata di funzione il codice relativo
							char s = calloc(1, sizeof(char));
							strcat(s, $1->code);
							strcat(s, "(");
							strcat(s, $3->code);
							strcat(s, ")");
							$1->code = s;
							//$1->code = prependString($1->code, prependString("(",prependString($3->code, ")")));
						}
						//ritorno $1
						$$ = $1;
						}
	| postfix_expression OSP expression COMMA expression CSP {
									printf("inizio della postfix della matrice\n");
									//controllo che le espressioni siano di tipo intero
									check_is_integer($3);
									check_is_integer($5);
									printf("dopo i controlli sul tipo delle espressioni\n");
									//controllo che il valore delle espressioni sia compreso nei parametri della matrice
									check_matrix_arguments($1, $3, $5);
									printf("dopo il controllo sugli argomenti della matrice\n");
									//controllo sia stata allocata memoria per la matrice
									check_mem_alloc($1);
									//ritorno un oggetto di tipo value con tipo settato al
									//tipo dei parametri della matrice
									value* temp = (value*)malloc(sizeof(value));
									temp->val = (int*)malloc(sizeof(int));
									//recupero il sym_rec del tipo della matrice
									sym_rec* temp_rec = (sym_rec*) get_sym_rec($1->type);
									temp->type = strdup(temp_rec->param_type);
									//associo il codice relativo alla dereferenziazione della matrice
									printf("prima delle strcat\n");
									char *s = calloc(1, sizeof(char));
									strcat(s, $1->code);
									strcat(s, "[");
									strcat(s, $3->code);
									strcat(s, ", ");
									strcat(s, $5->code);
									strcat(s, "]");
									temp->code = s;
									printf("dopo le strcat\n");
									//temp->code = prependString($1->code, prependString("[", prependString($3->code, prependString(",", prependString($5->code,"]")))));
									$$ = temp;
									printf("fine della postfix della matrice\n");
								}
	| postfix_expression OP exprlist CP {
						//se sono in una sezione normale
						if(functionDefinitions == 0) {
							//controllo se sia stato dichiarato l'identificatore
							sym_rec* rec = get_sym_rec($1);
							printf("Record %s trovato\n", $1);
							//creo il value
							value* temp = (value*) malloc(sizeof(value));
							//recupero il tipo dalla dichiarazione
							temp->type = strdup(rec->type);
							//overhead dovuto alla scarsa capacita' progettuale....
							temp->custom_type = strdup(rec->type);
							//recuper il nome
							temp->name = strdup(rec->text);
							//recuper il valore
							temp->val = rec->val;
							//ritorno il valore
							$$ = temp;
							//debbo controllare che i parametri inseriti corrispondano a quelli dichiarati nella func
							//richiamo una routine che prende in input il nome della funzione e la lista di argomenti
							check_function_arguments($1, $3);
							//associo al valore di ritorno il codice relativo
							char *s = calloc(1, sizeof(char));
							strcat(s, $1->code);
							strcat(s, "(");
							if($3 != 0) 
								strcat(s, $3->code);
							strcat(s, ")");
							$1->code = s;
							//$1->code = prependString($1->code, prependString("(", prependString($3->code, ")")));
							//ritorno il value corrispondente alla funzione, che cosi ho il tipo
							$$ = $1;
						}
						//altrimenti, salvo la funzione all'interno dell'apposita lista globale
						else {
							printf("inizio della postfix da non controllare\n");
							//creo elemento da aggiungere alla lista
							func* temp = (func*) malloc(sizeof(func));
							//recupero il nome della funzione utilizzata
							temp->name = strdup($1->name);
							//salvo la lista dei parametri utilizzati dalla funzione
							temp->param_list = $3;
							//aggiungo l'elemento in cima alla propria lista
							temp->next = func_list;
							func_list = temp;
							//associo il codice relativo all'uso della funzione
							char *s = calloc(1, sizeof(char));
							printf("prima del primo strcat\n");
							strcat(s, $1->code);
							printf("dopo il primo strcat\n");
							strcat(s, "(");
							printf("dopo il secondo strcat\n");
							if($3 != 0)
								strcat(s, $3->code);
							printf("dopo il terzo strcat\n");
							strcat(s, ")");
							$1->code = s;
							printf("fine della postfix\n");
							//$1->code = prependString($1->code, prependString("(", prependString($3->code, ")")));
						}
					}
	| postfix_expression ARROW IDENTIFIER {
						//debbo controllare che l'identificatore esista per quel tipo di record
						check_record_arguments($1, $3);
						printf("record field\n");
						//controllo l'allocazione di memoria per il record
						check_mem_alloc($1);
						//debbo passare come value quello corrispondente al campo del record
						value* temp = get_record_field($1, $3);
						//exit;
						char *s = calloc(1, sizeof(char));
						strcat(s, $1->code);
						strcat(s, "->");
						strcat(s, $3);
						temp->code = s;
						//temp->code = prependString($1->code, prependString("->", $3));
						$$ = temp;
					      }
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

primary_expression : IDENTIFIER {
					//se non sono all'interno della definizione di una funzione
					if(functionDefinitions == 0) {
						//controllo se sia stato dichiarato l'identificatore
						printf("controllo l'identificatore \n");
						sym_rec* rec = get_sym_rec($1);
						if(rec == 0 ) {
							printf("Identificarore %s non trovato\n", $1);
							exit(1);
						}
						else {
							printf("Record %s trovato\n", $1);
							//creo il value
							value* temp = (value*) malloc(sizeof(value));
							//recupero il tipo dalla dichiarazione
							temp->type = strdup(rec->type);
							//overhead dovuto alla scarsa capacita' progettuale....
							temp->custom_type = strdup(rec->type);
							//recuper il nome
							temp->name = strdup(rec->text);
							//associo il pezzo di codice necessario
							temp->code = strdup(rec->text);
							//recuper il valore
							temp->val = rec->val;
							//ritorno il valore
							$$ = temp;
						}
					}
					//altrimenti , non effettuo i normali controlli semantici
					else {
						//provo comunque a cercare l'identificatore
						//potrebbe esser una variabile inserita nella symbol table
						sym_rec* rec = get_sym_rec($1);
						if(rec == 0 ) {
							//salvo l'identificatore trovato nella lista globale degli identificatori
							func* temp = malloc(sizeof(func));
							temp->name = strdup($1);
							//associo il codice relativo
							temp->code = strdup($1);
							//salvo l'elemento in cima alla lista
							temp->next = identifier_list;
							identifier_list = temp;
							//creo l'elemento da ritornare come primary_expression
							//salvo solamente il nome
							value* val = malloc(sizeof(value));
							val->name= strdup($1);
							val->type = "unidentified";
							val->code = strdup($1);
							$$ = val;

						}
						else {
							printf("Record %s trovato\n", $1);
							//creo il value
							value* temp = (value*) malloc(sizeof(value));
							//recupero il tipo dalla dichiarazione
							temp->type = strdup(rec->type);
							//overhead dovuto alla scarsa capacita' progettuale....
							temp->custom_type = strdup(rec->type);
							//recuper il nome
							temp->name = strdup(rec->text);
							//recuper il valore
							temp->val = rec->val;
							//associo il codice relativo
							temp->code = strdup(rec->text);
							//ritorno il valore
							$$ = temp;
						}

											}

				}
	| constant {
	 						$$ = $1;
							}
	| STRING {
						//creo la stringa
						value* temp = (value*) malloc(sizeof(value));
						temp->val = strdup($1);
						//associo il codice
						temp->code = strdup($1);
						temp->type = "string";
						$$ = temp;
		}
	| OP expression CP {
	 										//associo il codice associato alle parentesi
											char *s = calloc(1, sizeof(char));
											strcat(s, "(");
											strcat(s, $2->code);
											strcat(s, ")");
											$2->code = s;
											//$2->code = prependString("(", prependString($2->code, ")"));
											$$ = $2;
											}
	;

constant : INTEGER_CONSTANT {
				value* temp = (value*) malloc(sizeof(value));
				temp->val = malloc(sizeof(int)); *((int*)(temp->val)) = $1;
				temp->type = "integer";
				//associo il codice alla costante intera
				temp->code = malloc(sizeof(char)*10);
				sprintf(temp->code, "%d", $1);
				$$ = temp;
			}
	| CHARACTER_CONSTANT {
													value* temp = (value*) malloc(sizeof(value));
													temp->val = strdup($1);
													temp->code = strdup($1);
													temp->type = "character";
													$$ = temp;
													}
	| FLOATING_CONSTANT {
												value* temp = (value*) malloc(sizeof(value));
												temp->val = malloc(sizeof(double));
												*((double*)(temp->val)) = $1;
												temp->type = "floating";
												//associo il codice al valore di ritorno
												sprintf(temp->code, "%f", $1);
												$$ = temp;
												}
	;


varlistdecl :
	/* empty */
	| varlistdecl vardecl
	;

vardecl : NEWVARS type varlist var  SEMI_COLON  {
						printf("Dentro la dichiarazione di nuove variabili\n");
						//variabile utility per l'allocazione
						int alloc = 0;
						if(is_base_type($2) == 1) {
							alloc = 1;
						}
						else {
							//controllo che il tipo sia stato definito
							sym_rec* r = get_sym_rec($2);
							if(r == 0) {
								printf("Tipo %s non trovato\n", $2);
								exit(1);
							}
						}
			
						//per ciascun paramentro aggiungo simbolo
						sym_rec* symbol;
						param* temp;
						int flag = $3;
						if(flag != 0) {
							for(temp = $3; temp != 0; temp = temp->next) {
								symbol = (sym_rec*) malloc(sizeof(sym_rec));
								symbol->text = strdup(temp->name);
								symbol->type = strdup($2);
								symbol->memoryAllocated = alloc;
								//inserisco il simbolo nella symbol table
								insert_sym_rec(symbol);
								printf("Inserisco simbolo %s di tipo %s\n", symbol->text, symbol->type);
							}

						}
						//inserico val
						//aggiungo il codice da generare
						symbol = (sym_rec*) malloc(sizeof(sym_rec));
						char *s = calloc(1, sizeof(char));
						strcat(s, "newvars ");
						strcat(s, $2);
						if($3 != 0) 
							strcat(s, $3->code);
						strcat(s, $4);
						strcat(s, ";\n");
						symbol->code = s;
						printf("dopo l'assegnamento\n");
						//symbol->code = prependString("newvars ", prependString($2, prependString($3, prependString($4, ";\n"))));
						printf("%s ", symbol->code );
						symbol->text = strdup($4->name);
						symbol->type = strdup($2);
						symbol->memoryAllocated = alloc;
						initialize_value(symbol);
						insert_sym_rec(symbol);
						printf("Inserisco simbolo %s di tipo %s\n", symbol->text, symbol->type);
						printf("Fine dichiarazione nuove variabili\n");
						}
	;

var : IDENTIFIER {
		//creo la lista di variabili come parametri
		param* temp = (param*) malloc(sizeof(param));
		temp->name = strdup($1);
		temp->code = strdup($1);
		$$ = temp;
		}
	;

varlist :
	/* empty */ { $$ = 0;  }
	| varlist var COMMA {
				//aggiungo la lista a var
				$2->next = $1;
				//aggiungo il codice generato
				if($1 == 0) {
					char *s = calloc(1, sizeof(char));
					strcat(s, $2->code);
					strcat(s, ", ");
					$2->code = s;
					//$2->code = prependString($2->code, ", ");
				}
				else {
					char *s = calloc(1, sizeof(char));
					strcat(s, $1);
					strcat(s, $2);
					strcat(s, ", ");
					$2->code = s;
					//$2->code = prependString($1, prependString($2, ", "));
				}
				$$ = $2;
			    }
	;
deffunclist_check : deffunclist {
					printf("controllo alla fine delle definizioni di funzione\n");
					//controllo alla fine delle dichiarazioni di tutte le funzioni , controllo che siano state tutte dichiarate
					func* temp;
					temp = func_list_total;
					if((int)(temp) != 0) {
						do  {
							//cerco il record nella symbol table corrispondente alla funzione utilizzata
							sym_rec* rec = get_sym_rec(temp->name);
							if((int)(rec) == 0) {
								printf("Funzione %s non trovato\n", temp->name);
								exit(1);
							}
							temp = temp->next;
						}
						while((int)(temp) != 0);

					}
				}
	;

deffunclist :
	/* empty */
	| deffunclist deffunc
	;

deffunc : FUNC IDENTIFIER OP params CP COLON type block { //inserisco nella symbol table il simbolo corrispondente alla funzione
							printf("controllo prima dell'inserimento della nuova funzione nella symbol table\n");
							sym_rec *func = (sym_rec*) malloc(sizeof(sym_rec));
							//inserisco nome della funzione
							func->text = strdup($2);
							//inserisco il tipo di ritorno della funzione
							//controllo che il tipo sia esistente
							if(!is_base_type($7) && strcmp($7, "null") != 0) {
								//controllo che esista un record corrispondente al tipo custom
								get_sym_rec($7);
							}
							func->type = strdup($7);
							//inserisco i parametri
							func->par_list = $4;
							//inserisco il simbolo appena creato nella symbol table
							insert_sym_rec(func);
							printf("Inserito simbolo per la funzione %s\n", func->text);
							//reimposto il flag per la sezione di normale parsing
							//all'ultima definizione di funzione rimarra' 0
							functionDefinitions = 0;
							}


	;

main : FUNC_EXEC OP params CP COLON type block  { //inserisco nella symbol table il simbolo corrispondente alla funzione
							sym_rec *func = (sym_rec*) malloc(sizeof(sym_rec));
							//inserisco nome della funzione
							func->text = "exec";
							//controllo che il tipo di ritorno di exec sia null o integer
							if(strcmp($6, "integer") != 0 && strcmp($6, "null") != 0) {
								printf("Tipo di ritorno per la funzione exec non valido\n");
								exit(1);
							}
							//inserisco il tipo di ritorno della funzione
							func->type = strdup($6);
							//inserisco i parametri
							func->par_list = $3;
							//controllo che i parametri della funzione exec siano tutti di tipo base
							check_param_list_base_type(func->par_list);
							//controllo che il tipo di ritorno della funzione sia integer o null
							if(strcmp($6, "integer") != 0 && strcmp($6, "null")) {
								printf("Tipo di ritorno non valido per la funzione exec\n");
								exit(1);
							}
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
			rec->memoryAllocated = 0;
			initialize_value(rec);
			insert_sym_rec(rec);
			printf("Inserito simbolo %s di tipo %s\n", rec->text, rec->type);
			}
	;

block : BEG body END
	;

body : declist_check varlistdecl stmts
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
	| printf_statement
	| scanf_statement
	;
scanf_statement: SCANF OP STRING printf_temp CP SEMI_COLON

printf_statement: PRINTF OP STRING  printf_temp CP SEMI_COLON

printf_temp: 
	| /* empty */
	| COMMA  exprlist
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

assignment_statement : unary_expression assignment_operator expression SEMI_COLON { printf("Dentro l'assignment statement\n");
											if(strcmp($1->type, "unidentified") != 0 && strcmp($3->type, "unidentified") != 0)
												check_type($1,$3);
											copy_val($1,$3);
											printf("Fine dell'assignment statement\n");
										}
	| expression SEMI_COLON
	/* eliminata statements fatta da solo SEMI_COLON */
	;

object_statement : FREE OP IDENTIFIER CP SEMI_COLON {
							value* val;
							val = (value*) malloc(sizeof(value));
							val->name = strdup($3);
							//dealloco la memoria
							dealloc_mem(val);
						    }
	| unary_expression ASSIGN  NEW OP IDENTIFIER CP SEMI_COLON {
									//debbo controllare che l'unary_expression sia dello stesso tipo
									//identificato dall'identifier
									value* temp;
									temp = (value*) malloc(sizeof(value));
									temp->type = strdup($5);
									check_type($1, temp);
									//alloco memoria per il valore dell'unary_expression
									alloc_mem($1);
								   }
	;

overloads :
	/*empty */
	| overloads overload
	;

overload : OVERLOAD OP overloadable_operands COMMA IDENTIFIER CP BEG stmts END  {
											//debbo inserire l'overload
											sym_rec* rec = (sym_rec*)malloc(sizeof(sym_rec));
											rec->operand = strdup($3);
											rec->type = strdup($5);
											rec->text = "";
											insert_sym_rec(rec);
										 }
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

int yyerror (char const *s) {
	printf("errore \n");
}

main(int argc, char* argv[]) {
	//file per la lettura da sorgente
        FILE* f;
	//variabile corrispondente al buffer del lexer
	extern FILE* yyin;
	//inizializzo la symbol table
	extern sym_table* top ;
	//inizializzo la lista delle definizioni di funzione
	extern func* func_list;
	func_list = 0;
	extern func* func_list_global;
	func_list_total = 0;
	//inizializzo la lista degli identificatori utilizzati all'interno delle definizioni di funzione
	extern func* identifier_list;
	identifier_list = 0;
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
