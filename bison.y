%{
	#include <stdio.h>
	#include <stdlib.h>
	#include <string.h>
	#include "SM.h"

	#define YYDEBUG 1

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
%token <str> ASSIGN
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
%type <str> basetype assignment_operator
%type <par> param parlist params var varlist field fieldlist
%type <val> constant primary_expression expression conditional_expression logical_or_expression logical_and_expression logical_not_expression exclusive_or_expression and_expression equality_expression relational_expression shift_expression additive_expression multiplicative_expression exp_expression cast_expression unary_expression postfix_expression exprlist exprlist_temp arrayexpr block body stmt stmts varlistdecl vardecl declist_check assignment_statement selection_statement iteration_statement object_statement jump_statement printf_statement scanf_statement  printf_temp scanf_temp jump_temp declist decl deffunclist_check overloads main  deffunc deffunclist
%type <symrec> typebuilder
%type <str> overloadable_operands

%start S

%%

/* grammar starting symbol */
S : declist_check deffunclist_check overloads varlistdecl main EOF_TOKEN  	{
											//including some libs
											printf("#include<stdio.h>\n");
											printf("#include<stdlib.h>\n");
											printf("#include<string.h>\n");
											//printing every source component translated
											if($1 != 0)
												printf("%s",$1->code);
											if($2 != 0)
												printf("%s",$2->code);
											if($4 != 0)
												printf("%s", $4->code);
											if($5 != 0)
												printf($5->code);

											 printf("//bison.y : parsato !\n");
											 return 0;
										 }
	;

declist_check : declist {
				int a = check_recursive_definitions();
				if( a== 0) {
					printf("bison.y: errore nella definizione delle funzioni ricorsive\n");
					exit(1);
				}
				//printf("//bison.y : fine della sezione di dichiarazione dei tipi\n");
				$$ = $1;
			}
	;
declist :
	/*empty */ { $$ = 0; }
	| declist decl {
				if($1 == 0) {
					$$ = $2;
				}
				else {
					//altrimenti , assegno $2 come successivo di $1
					$1->next = $2;
					$1->code = prependString($1->code, $2->code);
					$$ = $1;
				}
			}
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
						s = prependString(s,  "typedef ");
						//controllo se debbo inserire il nome della struttura dopo la keyword struct
						s = prependString(s,  $3->code);
						if(strstr(s, "struct") != 0 ) {
							s = insert_after_struct(s, $2);
						}
						s = prependString(s,  " ");
						if(strstr(s, "struct") != 0) {
							s = prependString(s,  "*");
						}
						s = prependString(s,  $2);
						s = prependString(s,  " ;\n");
						//printf("//bison.y: codice del nuovo tipo ");
						//printf("%s \n",s );
						//printf("//bison.y: alla fine della dichiarazione del nuovo tipo \n");
						//value per fare il bubbling del codice
						value* val = calloc(1, sizeof(value));
						val->code = s;
						val->name = 0;
						val->type = 0;
						//printf(s);
						$$ = val;
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
						//associo il codice
						char* s = calloc(1, sizeof(char));
						if($3 == 0) {
							s = prependString(s,  "struct { ");
							 s = prependString( s,  $4->code);
							 s = prependString( s,  "\n}\n");
							//allocating size for the string plus 1
							temp->code = calloc(strlen(s)+1, sizeof(char));
							//copying string s into temp->code
							memcpy(temp->code, s, strlen(s));
							//null terminating string
							temp->code[strlen(s)-1] = '\0';

						}else {
							s = prependString(s,  "struct { ");
							s = prependString(s,  $3->code);
							s = prependString(s,  "\n");
							s = prependString(s,  $4->code);
							s = prependString(s,  "\n}\n");
							//allocating size for the string plus 1
							temp->code = calloc(strlen(s)+1, sizeof(char));
							//copying string s into temp->code
							memcpy(temp->code, s, strlen(s));
							//null terminating string
							temp->code[strlen(s)-1] = '\0';

						}
						//printf("//bison.y: dopo l'if \n");
						//ritorno il sym_rec
						$$ = temp;
						//printf("//bison.y: codice del typebuilder del record %s\n", $$->code);
						//qui e' corretto , ma nella riduzione del nuovo tipo il codice viene tagliato

					}
	| MATRIX OP basetype COMMA expression COMMA expression CP {
						//controllo che il tipo delle espressioni sia intero
						//printf("//bison.y : all'inizio della riduzione del typebuilder della matrice\n");
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
						//printf("//bison.y : prima del salvataggio dei valori dei parametri della matrice \n");
						copy_val_in_param(temp_1, $5);
						copy_val_in_param(temp_2, $7);
						//printf("//bison.y : dopo il salvataggio dei valori dei parametri della matrice\n");
						//unisco i parametri
						temp_1->next = temp_2;
						//salvo i parametri
						temp->par_list = temp_1;
						//salvo il tipo della matrice
						temp->param_type = strdup($3);
						//setto current_param
						temp->current_param = temp->par_list;
						//aggiugo il codice al valore di ritorno
						char* s = calloc(1, sizeof(char));
						//printf("//bison.y : prima dell'aggiunta del tipo della matrice \n");
						if(strcmp($3, "integer")== 0)
							s = prependString(s,  "int** ");
						else
							s = prependString(s,  "double** ");
						temp->code = s;
						//ritorno il sym_rec
						$$ = temp;
						//printf("//bison.y : alla fine del typebuilder della matrice \n");
					}

	| ARRAY OP type COMMA arrayexpr expression CP {
							//printf("dentro la definizione dell'array\n");
							//creo il nuovo elemento per la symbol table
							sym_rec* rec = malloc (sizeof(sym_rec));
							rec->type = "array";
							//inizializzo la stringa che conterra' il codice corrispondente alla dichiarazione
							//del nuovo tipo array
							char* s = calloc(1, sizeof(char));
							//per ciacun valore, debbo creare il parametro
							value* temp;
							param* parlist = (param*) malloc(sizeof(param));
							param* parlisttemp;
							//creo il primo parametro
							copy_val_in_param(parlist, $6);
							//assegno anche il tipo del parametro
							//serve per controllo di definizioni ricorsive dei tipi
							parlist->type = strdup($3);
							s = prependString(s,  $3);
							s = prependString(s,  "*");
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
								s = prependString(s,  "*");
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
							rec->code = s;
							$$ = rec;
							//print_array_params(rec);
							}
	;

arrayexpr :
	 /* empty */ { $$ = 0; }
	| arrayexpr expression COMMA {
					//printf("inizio arrayexpr \n");
					//aggiungo il valore alla lista
					$2->next = $1;
					//printf("dopo next\n");
					//associo il codice al valore di ritorno
					if($1 == 0) {
						char *s = calloc(1, sizeof(char));
						s = prependString(s,  $2->code);
						s = prependString(s, ", ");
						$2->code = s;
						//$2->code = prependString(" ", prependString($2->code, ", "));
					}
					else {
						char *s = calloc(1, sizeof(char));
						s = prependString(s, $1->code);
						s = prependString(s, $2->code);
						s = prependString(s, ", ");
						$2->code = s;
						//$2->code = prependString($1->code, prependString($2->code, ", "));
					}
					$$ = $2;
					//printf("fine arrayexpr\n");
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
						s = prependString(s,  $2->code);
						$2->code = s;
						//$2->code = prependString(" ", prependString($2->code, ", "));
					}
					else {
						char *s = calloc(1, sizeof(char));
						s = prependString(s,  $1->code);
						s = prependString(s,  $2->code);
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
				//traduzione del tipo
				if(strcmp($1,"integer") == 0)
					s = prependString(s, "int ");
				else if(strcmp($1, "floating") == 0)
					s = prependString(s, "double ");
				else if(strcmp($1, "boolean"))
					s = prependString(s, "int ");
				else
					s = prependString(s, $1);
				s = prependString(s,  " ");
				s = prependString(s,  $2);
				s = prependString(s,  " ;\n");
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

expression : conditional_expression {
					printf("//bison.y : inizio della expression \n");
					 $$ = $1;
					printf("//bison.y : fine della expression\n");
					 }
	;

conditional_expression : logical_or_expression  { $$ = $1; }
	;

logical_or_expression : logical_and_expression {
																								$$ = $1;
																								}
	| logical_or_expression OR logical_and_expression {
																											value* temp = (value*) malloc(sizeof(value));
							    																		temp->val = (int*) malloc(sizeof(int));
						  temp->name = 0;
						  temp->type = 0;
							    																		*((int*)(temp->val)) = *((int*)($1->val)) || *((int*)($3->val));
								char *s = calloc(1, sizeof(char));
								s = prependString(s,  $1->code);
								s = prependString(s,  "||");
								s = prependString(s,  $3->code);
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
									temp->name = 0;
									temp->type = 0;
																												*((int*)(temp->val)) = *((int*)($1->val)) && *((int*)($3->val));
									char *s = calloc(1, sizeof(char));
									s = prependString(s,  $1->code);
									s = prependString(s,  "&&");
									s = prependString(s,  $3->code);
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
					s = prependString(s,  "!");
					s = prependString(s,  $2->code);
					temp->code = s;
					temp->name = 0;
					temp->type = 0;
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
								//printf("tipo di $1 %s tipo di $3 %s \n", $1->type, $3->type);
								if(strcmp($1->type, "unidentified") != 0 && strcmp($3->type, "unidentified") != 0)
									check_type($1, $3);
								temp->type = "boolean";
								temp->name = 0;
								//temp->val = (int*)malloc(sizeof(int));
								//*((int*)(temp->val)) = check_equal($1, $3);
								char *s = calloc(1, sizeof(char));
								s = prependString(s,  $1->code);
								s = prependString(s,  "==");
								s = prependString(s,  $3->code);
								temp->code = s;
								//temp->code = prependString($1->code, prependString("==", $3->code));
								$$ = temp;
							 }
	| equality_expression NOTEQUAL relational_expression   {
								value *temp = (value*) malloc(sizeof(value));
								if(strcmp($1->type, "unidentified") != 0 && strcmp($3->type, "unidentified") != 0)
									check_type($1, $3);
								temp->type = "boolean";
								temp->name = 0;
								//temp->val = (int*)malloc(sizeof(int));
								//*((int*)(temp->val)) = check_equal($1, $3);
								//aggiungo il codice al valore di ritorno
								char *s = calloc(1, sizeof(char));
								s = prependString(s,  $1->code);
								s = prependString(s,  "!=");
								s = prependString(s,  $3->code);
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
										s = prependString(s,  $1->code);
										s = prependString(s,  "+");
										s = prependString(s,  $3->code);
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
											 s = prependString(s,  $1->code);
											 s = prependString(s,  "-");
											 s = prependString(s,  $3->code);
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
								 s = prependString(s,  $1->code);
								 s = prependString(s,  "*");
								 s = prependString(s,  $3->code);
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
								 s = prependString(s,  $1->code);
								 s = prependString(s,  "/");
								 s = prependString(s,  $3->code);
								 temp->code = s;
																											//temp->code = prependString($1->code, prependString("/", $3->code));
																											$$ = temp;
																											}

	;

exp_expression : cast_expression { $$ = $1; }
	| exp_expression EXP cast_expression {
		printf("//bison.y : inizio della exp_expression\n");
																					value* temp = (value*) malloc(sizeof(value));
																					temp->type = strdup($3->type);
		  char *s = calloc(1, sizeof(char));
		  s = prependString(s,  $1->code);
		  s = prependString(s,  "#");
		  s = prependString(s,  $3->code);
		  temp->code = s;
																					//temp->code = prependString($1->code, prependString("#", $3->code));
																					$$ = temp;
		printf("//bison.y : fine dell exp_expression\n");
																					}
	;

cast_expression : unary_expression { 
					printf("//bison.y : inizio della cast_expression\n");
					$$ = $1; 
					printf("//bison.y : fine della cast_expression\n");
				}
	| FLOATING OP cast_expression CP {
																		check_is_integer($3);
																		value* temp = (value*) malloc(sizeof(value));
																		temp->type = "floating";
																		temp->val = (double*) malloc(sizeof(double));
																		*((double*)(temp->val)) = (double)(*((int*)($3->val)));
																		//associo il codice relativo alla espressione di cast
			char *s = calloc(1, sizeof(char));
			s = prependString(s,  "floating");
			s = prependString(s,  "(");
			s = prependString(s,  $3->code);
			s = prependString(s,  ")");
			temp->code = s;
																		//temp->code = prependString("floating", prependString("(", prependString($3->code, ")")));
																		$$ = temp; }
	;


assignment_operator : ASSIGN { $$ = $1;}
	;

unary_operator : MINUS
	;

unary_expression : postfix_expression {
					printf("//bison.y : inizio della unary expression\n");
					 $$ = $1;
					reset_current_param($1);
					printf("//bison.y : fine della unary expression\n");
					}
	| unary_operator cast_expression {
																		change_sign($2);
																		//associo al valore di ritorno il codice relativo
				char *s = calloc(1, sizeof(char));
				s = prependString(s,  "-");
				s = prependString(s,  $2->code);
				$2->code = s;
					//													$2->code = prependString("-", $2->code);
																		$$ = $2;
																		}
	;

postfix_expression : primary_expression {
					printf("//bison.y : postfix della primary \n");
 					//controllo se sia stato dichiarato l'identificatore
					 $$ = $1;
					printf("//bison.y : fine della postfix della primary \n");
					 }
	| postfix_expression OSP expression CSP {
						printf("//bison.y : dentro la postfix per array\n");
						//debbo controllare che l'espressione inserita sia compatibile con le espressioni inserite
						//in primis, essendo indice di array, controllo che expression sia integer
						check_is_integer($3);
						printf("//bison.y : dopo controllo intero\n");
						//in secundis, controllo che il valore dell'espressione sia compreso nel limite dell'array
						//print_array_params(get_sym_rec($1->name));
						//siccome non voglio cambiare la funzione check , creo un nuovo val...
						//lebensraum
						value* val = (value*)malloc(sizeof(value));
						val->name = strdup($1->name);
						printf("//bison.y : dopo assegnazione del nome\n");
						val->type = strdup($1->custom_type);
						printf("//bison.y : dopo assegnazione del tipo\n");
						check_array_arguments(val, $3);
						printf("//bison.y : dopo check degli argomenti dell'array\n");
						//controllo che sia stata allocata memoria per l'array
						check_mem_alloc($1);
						printf("//bison.y : dopo check dell'allocazione della memoria \n");
						//sto dereferenziando array , quindi modifico il tipo
						if(is_base_type($1->type) == 0) {
							printf("//bison.y : se e' tipo base\n");
							//recupero il record corrispondente al tipo dell'array
							sym_rec* type = (sym_rec*)get_sym_rec($1->type);
							$1->type = strdup(type->param_type);
							//associo alla chiamata di funzione il codice relativo
							char* s = calloc(1, sizeof(char));
							s = prependString(s,  $1->code);
							s = prependString(s,  "[");
							s = prependString(s,  $3->code);
							s = prependString(s,  "]");
							$1->code = s;
							//$1->code = prependString($1->code, prependString("(",prependString($3->code, ")")));
						}
						//ritorno $1
						$$ = $1;
						printf("//bison.y : fine della postfix per array\n");
						}
	| postfix_expression OSP expression COMMA expression CSP {
									printf("//bison.y : inizio della postfix della matrice\n");
									//controllo che le espressioni siano di tipo intero
									check_is_integer($3);
									check_is_integer($5);
									printf("//bison.y : dopo i controlli sul tipo delle espressioni\n");
									//controllo che il valore delle espressioni sia compreso nei parametri della matrice
									check_matrix_arguments($1, $3, $5);
									printf("//bison.y : dopo il controllo sugli argomenti della matrice\n");
									//controllo sia stata allocata memoria per la matrice
									check_mem_alloc($1);
									//ritorno un oggetto di tipo value con tipo settato al
									//tipo dei parametri della matrice
									value* temp = (value*)malloc(sizeof(value));
									temp->val = (int*)malloc(sizeof(int));
									temp->name = strdup($1->name);
									//recupero il sym_rec del tipo della matrice
									sym_rec* temp_rec = (sym_rec*) get_sym_rec($1->type);
									temp->type = strdup(temp_rec->param_type);
									temp->custom_type = strdup(temp_rec->text);
									//associo il codice relativo alla dereferenziazione della matrice
									printf("//bison.y : prima delle prependString\n");
									char *s = calloc(1, sizeof(char));
									s = prependString(s,  $1->code);
									s = prependString(s,  "[");
									s = prependString(s,  $3->code);
									s = prependString(s, "][");
									s = prependString(s,  $5->code);
									s = prependString(s,  "]");
									temp->code = s;
									//printf("dopo le prependString\n");
									//temp->code = prependString($1->code, prependString("[", prependString($3->code, prependString(",", prependString($5->code,"]")))));
									$$ = temp;
									printf("//bison.y : fine della postfix della matrice\n");
								}
	| postfix_expression OP exprlist CP {
						//se sono in una sezione normale
						if(functionDefinitions == 0) {
							//controllo se sia stato dichiarato l'identificatore
							sym_rec* rec = get_sym_rec($1);
							//printf("Record %s trovato\n", $1);
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
							s = prependString(s,  $1->code);
							s = prependString(s,  "(");
							if($3 != 0)
								s = prependString(s,  $3->code);
							s = prependString(s,  ")");
							$1->code = s;
							//$1->code = prependString($1->code, prependString("(", prependString($3->code, ")")));
							//ritorno il value corrispondente alla funzione, che cosi ho il tipo
							$$ = $1;
						}
						//altrimenti, salvo la funzione all'interno dell'apposita lista globale
						else {
							//printf("inizio della postfix da non controllare\n");
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
							//printf("prima del primo prependString\n");
							s = prependString(s,  $1->code);
							//printf("dopo il primo prependString\n");
							s = prependString(s,  "(");
							//printf("dopo il secondo prependString\n");
							if($3 != 0)
								s = prependString(s,  $3->code);
							//printf("dopo il terzo prependString\n");
							s = prependString(s,  ")");
							$1->code = s;
							//printf("fine della postfix\n");
							//$1->code = prependString($1->code, prependString("(", prependString($3->code, ")")));
						}
					}
	| postfix_expression ARROW IDENTIFIER {
						//debbo controllare che l'identificatore esista per quel tipo di record
						check_record_arguments($1, $3);
						//printf("record field\n");
						//controllo l'allocazione di memoria per il record
						check_mem_alloc($1);
						//debbo passare come value quello corrispondente al campo del record
						value* temp = get_record_field($1, $3);
						temp->custom_type = strdup($1->type);
						//exit;
						char *s = calloc(1, sizeof(char));
						s = prependString(s,  $1->code);
						s = prependString(s,  "->");
						s = prependString(s,  $3);
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
					printf("//bison.y : primay expression \n");
					//se non sono all'interno della definizione di una funzione
					if(functionDefinitions == 0) {
						printf("//bison.y : functionDefinitions = 0 \n");
						//controllo se sia stato dichiarato l'identificatore
						printf("//bison.y : controllo l'identificatore %s \n", $1);
						sym_rec* rec = get_sym_rec($1);
						printf("//bison.y : dopo aver preso il rec \n");
						if(rec == 0 ) {
							printf("Identificarore %s non trovato\n", $1);
							exit(1);
						}
						else {
							//printf("Record %s trovato\n", $1);
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
							//printf("Record %s trovato\n", $1);
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
					printf("//bison.y : fine della primary expression \n");

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
						temp->name = 0;
						temp->type = "string";
						$$ = temp;
		}
	| OP expression CP {
	 										//associo il codice associato alle parentesi
											char *s = calloc(1, sizeof(char));
											s = prependString(s,  "(");
											s = prependString(s,  $2->code);
											s = prependString(s,  ")");
											$2->code = s;
											//$2->code = prependString("(", prependString($2->code, ")"));
											$$ = $2;
											}
	;

constant : INTEGER_CONSTANT {
				value* temp = (value*) malloc(sizeof(value));
				temp->val = malloc(sizeof(int)); *((int*)(temp->val)) = $1;
				temp->type = "integer";
				temp->name = 0;
				//associo il codice alla costante intera
				temp->code = malloc(sizeof(char)*10);
				sprintf(temp->code, "%d", $1);
				$$ = temp;
			}
	| CHARACTER_CONSTANT {
													value* temp = (value*) malloc(sizeof(value));
													temp->val = strdup($1);
													temp->code = strdup($1);
													temp->name = 0;
													temp->type = "character";
													$$ = temp;
													}
	| FLOATING_CONSTANT {
												value* temp = (value*) malloc(sizeof(value));
												temp->val = malloc(sizeof(double));
												temp->name = 0;
												*((double*)(temp->val)) = $1;
												temp->type = "floating";
												//associo il codice al valore di ritorno
												sprintf(temp->code, "%f", $1);
												$$ = temp;
												}
	;


varlistdecl :
	/* empty */ { $$ = 0; }
	| varlistdecl vardecl {
				$2->next = $1;
				if($1 != 0 ) {
					$2->code = prependString($1->code, $2->code);
				}
				$$ = $2;
			      }
	;

vardecl : NEWVARS type varlist var  SEMI_COLON  {
						//printf("//bison.y : Dentro la dichiarazione di nuove variabili\n");
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
								printf("//bison.y : Inserisco simbolo %s di tipo %s\n", symbol->text, symbol->type);
							}

						}
						//inserico val
						//aggiungo il codice da generare
						symbol = (sym_rec*) malloc(sizeof(sym_rec));
						char *s = calloc(1, sizeof(char));
						if(strcmp($2, "integer") == 0)
							s = prependString(s, "int ");
						else if(strcmp($2, "floating") == 0)
							s = prependString(s, "double ");
						else if(strcmp($2, "boolean") == 0)
							s = prependString(s, "int ");
						else if(strcmp($2, "string") == 0)
							s = prependString(s, "char* ");
						else
							s = prependString(s,  $2);
						s = prependString(s,  " ");
						if($3 != 0)
							s = prependString(s,  $3->code);
						s = prependString(s,  $4->code);
						//printf("//bison.y : dopo agigunta delle variabili al codice della dichiarazione \n");
						//printf("//bison.y : valori delle variabili da dichiarare %s \n" , $4->code);
						s = prependString(s,  ";\n");
						symbol->code = s;
						//printf("// bison.y : dopo l'assegnamento\n");
						//symbol->code = prependString("newvars ", prependString($2, prependString($3, prependString($4, ";\n"))));
						//printf("%s ", symbol->code );
						symbol->text = strdup($4->name);
						symbol->type = strdup($2);
						symbol->memoryAllocated = alloc;
						initialize_value(symbol);
						printf("//bison.y : Inserisco simbolo %s di tipo %s \n", symbol->text, symbol->type);
						insert_sym_rec(symbol);
						//printf("//bison.y : codice della dichiarazione delle variabili \n");
						//printf("%s\n", s);
						//printf("//bison.y : Fine dichiarazione nuove variabili\n");
						value* val = (value*)calloc(1, sizeof(value));
						val->name = strdup($4->name);
						val->type = strdup($2);
						val->code = s;
						$$ = val;
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
					s = prependString(s,  $2->code);
					s = prependString(s, ", ");
					$2->code = s;
				}
				else {
					char *s = calloc(1, sizeof(char));
					s = prependString(s,  $1);
					s = prependString(s,  $2);
					s = prependString(s, ", ");
					$2->code = s;
				}
				$$ = $2;
				//printf("//bison.y : fine della reduce della varlist \n");
			    }
	;
deffunclist_check : deffunclist {
					//printf("controllo alla fine delle definizioni di funzione\n");
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
					$$ = $1;
				}
	;

deffunclist :
	/* empty */ {  $$ = 0;
			//printf("//bison.y : nessuna dichiarazione di funzione\n");
		    }
	| deffunclist deffunc {
				//printf("//bison.y : dichiarazioni di funzione presenti\n");
				if($1 == 0) {
					$$ = $2;
				}
				else {
					$1->code = prependString($1->code, $2->code);
					$$ = $1;
				}
			      }
	;

deffunc : FUNC IDENTIFIER OP params CP COLON type block { //inserisco nella symbol table il simbolo corrispondente alla funzione
							//printf("//bison.y : controllo prima dell'inserimento della nuova funzione nella symbol table\n");
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
							//printf("//bison.y : Inserito simbolo per la funzione %s\n", func->text);
							//reimposto il flag per la sezione di normale parsing
							//all'ultima definizione di funzione rimarra' 0
							functionDefinitions = 0;
							//inserisco il codice C corrispondente alla funzione
							//printf("//bison.y : prima della costruzione del codice della funzione\n");
							char* s = calloc(1, sizeof(char));
							if(strcmp($7, "integer") == 0 )
								s = prependString(s,  "int ");
							else if(strcmp($7, "floating ") == 0)
								s = prependString(s,  "double ");
							else if(strcmp($7, "boolean ") == 0)
								s = prependString(s,  "int ");
							else
								s = prependString(s,  $7);
							//printf("//bison.y : dopo inserimento del tipo di ritorno della funzione\n");
							s = prependString(s,  $2);
							//printf("//bison.y : dopo inserimento del nome della funzione\n");
							s = prependString(s,  " ( ");
							if($4 != 0)
								s = prependString(s,  $4->code);
							//printf("//bison.y : dopo inserimento del codice per i parametri della funzione\n");
							s = prependString(s,  " ) ");
							s = prependString(s,  $8->code);
							//printf("//bison.y : dopo inserimento del codice per il body della funzione\n");
							//stampo il codice relativo alla definizione della nuova funzione
							//printf("//bison.y : codice della definizione della nuova funzione\n");
							//printf("%s\n", s);
							value* val = (value*)calloc(1, sizeof(value));
							val->name = strdup($2);
							val->type = strdup($7);
							val->code = s;
							$$ = val;
							}


	;

main : FUNC_EXEC OP params CP COLON type block  { //inserisco nella symbol table il simbolo corrispondente alla funzione
							printf("//bison.y : inizio della sezione della main\n");
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
							printf("//bison.y : dopo controllo dei paramentri della exec\n");
							//controllo che il tipo di ritorno della funzione sia integer o null
							if(strcmp($6, "integer") != 0 && strcmp($6, "null")) {
								printf("Tipo di ritorno non valido per la funzione exec\n");
								exit(1);
							}
							//inserisco il simbolo appena creato nella symbol table
							printf("//bison.y : prima dell'inserimento del sym_rec per la main\n");
							printf("//bison.y : puntatore al sym_rec della funzione %d\n", func);
							insert_sym_rec(func);
							//printf("Inserito simbolo per la funzione %s\n", func->text);
							//creo il codice per la funzione main
							char* s = calloc(1, sizeof(char));
							if(strcmp($6, "integer") == 0 || strcmp($6, "boolean") == 0) {
								s = prependString(s,  "int ");
							}
							else if(strcmp($6, "floating") == 0) {
								s = prependString(s,  "double ");
							}
							else if(strcmp($6, "void") == 0) {
								s = prependString(s,  "void ");
							}
							else {
								s = prependString(s,  $6);
							}
							printf("//bison.y : dopo il tipo della main\n");
							s = prependString(s,  "main(");
							if($3 != 0)
								s = prependString(s,  $3->code);
							printf("//bison.y : dopo il codice dei parametri\n");
							s = prependString(s,  ")\n");
							s = prependString(s,  $7->code);
							//printf("//bison.y : codice del main \n");
							value* val = (value*)calloc(1, sizeof(value));
							val->name = "main";
							val->type = strdup($7);
							val->code = s;
							$$ = val;
							}

	;

params :
	/* empty */ { $$ = 0; }
	| parlist param {
			//printf("//bison.y : inizio della sezione di params\n");
			$2->next = $1;
			//printf("//bison.y : dopo assegnazione dell'elemento della lista\n");
			if($1 != 0)
				$2->code = prependString($2->code, $1->code);
			//printf("//bison.y : dopo il prepend\n");
			$$ = $2;
			//stampo tutti i parametri
			//printf("//bison.y : fine della sezione di params\n");
			}
	;

parlist :
	/* empty */ { $$ = 0; }
	| parlist param COMMA {//provo cosi. salvo il valore di ritorno di parlist come next element di param
				//printf("//bison.y : inzio della sezione della lista delle parametri\n");
				$2->next = $1;
				if($1 != 0 )
					$2->code = prependString($2->code, $1->code);
				//ritorno la lista completa
				$$ = $2;
				}
	;

param : type IDENTIFIER {//prova di aggiunta di simbolo
			//alloco spazio per il parametro
			//printf("//bison.y : inizio della sezione relativa ad un parametro \n");
			param* temp = (param*) malloc(sizeof(param));
			//associo i valori
			temp->name = strdup($2);
			temp->type = strdup($1);
			//inserisco il codice per il parametro
			char* s = calloc(1, sizeof(char));
			if(strcmp($1,"integer") == 0)
				s = prependString(s, "int ");
			else if(strcmp($1, "floating") == 0)
				s = prependString(s, "double ");
			else if(strcmp($1, "boolean"))
				s = prependString(s, "int ");
			else
				s = prependString(s, $1);
			s = prependString(s,  " ");
			s = prependString(s,  $2);
			temp->code = s;
			//ritorno il parametro
			$$ = temp;
			//inserisco il simbolo nella symbol table
			sym_rec* rec = (sym_rec*)malloc(sizeof(sym_rec));
			rec->text = strdup($2);
			rec->type = strdup($1);
			rec->memoryAllocated = 0;
			initialize_value(rec);
			insert_sym_rec(rec);
			//printf("//bison.y : Inserito simbolo %s di tipo %s\n", rec->text, rec->type);

			}
	;

block : BEG body END {
			printf("//bison.y : inizio della sezione del blocco \n");
			char* s = calloc(1, sizeof(char));
			s = prependString(s,  "{\n");
			if($2 != 0)
				s = prependString(s,  $2->code);
			s = prependString(s,  "\n}\n");
			$2->code = s;
			$$ = $2;
			printf("//bison.y : fine della sezione del blocco \n");
			}
	;

body : declist_check varlistdecl stmts {
						printf("//bison.y : inizio della sezione relativa al body\n");
						value* temp = calloc(1, sizeof(value));
						char* s = calloc(1, sizeof(char));
						//printf("//bison.y : prima del primo prepend\n");
						if($1 != 0)
							s = prependString(s,  $1->code);
						//printf("//bison.y : dopo il primo prepend \n");
						s = prependString(s,  "\n ");
						//printf("//bison.y : dopo il secondo prepend \n");
						if($2 != 0)
							s = prependString(s,  $2->code);
						//printf("//bison.y : dopo il prepend boh \n");
						s = prependString(s,  "\n");
						if($3 != 0)
							s = prependString(s,  $3->code);
						s = prependString(s,  "\n");
						temp->code = s;
						$$ = temp;
						printf("//bison.y : fine della sezione relativa al body\n");
					}
	;

stmts :
	/* empty */  { $$ = 0; }
	| stmts stmt  {
				if($1 == 0) {
					$$ = $2;
				}
				else {
					$1->next = $2;
					$1->code = prependString($1->code, $2->code);
					printf("//bison.y : dentro stmts\n");
					$$ = $1;
				}
			}
	;

stmt :	assignment_statement { $$ = $1; }
	| block { $$ = $1; }
	| selection_statement { $$ = $1; }
	| iteration_statement  { $$ = $1; }
	| object_statement  { $$ = $1; }
	| jump_statement  { $$ = $1; }
	| printf_statement   { $$ = $1; }
	| scanf_statement  { $$ = $1; }
	;
scanf_statement: SCANF OP STRING scanf_temp CP SEMI_COLON {
								value* val = calloc(1, sizeof(value));
								char* s = calloc(1, sizeof(char));
								s = prependString(s,  "scanf(");
								char* hello = escape_percent($3);
								s = prependString(s, "\"");
								s = prependString(s,  hello);
								s = prependString(s, "\"");
								if($4 != 0)
									s = prependString(s,  $4->code);
								s = prependString(s,  ");\n");
								val->code = s;
								$$ = val;
							   }

printf_statement: PRINTF OP STRING  printf_temp CP SEMI_COLON	{
									printf("//bison.y : inizio della printf statement\n");
									value* val = calloc(1,sizeof(value));
									char* s = calloc(1, sizeof(char));
									s = prependString(s,  "printf(");
									printf("//bison.y : prima della prepend della string literal\n");
									char* hello = escape_percent($3);
									s = prependString(s, "\"");
									s = prependString(s,  hello);
									s = prependString(s, "\"");
									printf("\n//bison.y : dopo prepend della string literal\n");
									printf("//bison.y : printf_temp %d \n", $4);
									if($4 != 0)
										s = prependString(s,  $4->code);
									printf("//bison.y : dopo prepend del codice della printf\n");
									s = prependString(s,  ");\n");
									val->code = s;
									//printf("//bison.y : codice della printf %s\n", s);
									printf("//bison.y : fine della printf statement\n");
									$$ = val;
								}


printf_temp:
	/* empty */  { $$ = 0; printf("//bison.y : ciao\n"); }
	| COMMA  exprlist {
				printf("//bison.y : dentro printf_temp\n");
				char* s = calloc(1, sizeof(char));
				s = prependString(s, ", ");
				s = prependString(s, $2->code);
				printf("//bison.y : stampa del codice di exprlist %s \n", $2->code);
				$2->code = s;
				$$ = $2;
			}
	;

scanf_temp:
	/* empty */  { $$ = 0; printf("//bison.y : ciao\n"); }
	| COMMA  exprlist {
				printf("//bison.y : dentro printf_temp\n");
				char* s = calloc(1, sizeof(char));
				s = prependString(s, ", ");
				s = prependString(s, "&");
				s = prependString(s, $2->code);
				printf("//bison.y : stampa del codice di exprlist %s \n", $2->code);
				$2->code = s;
				$$ = $2;
			}
	;




jump_statement : RETURN jump_temp SEMI_COLON {
						char* s = calloc(1, sizeof(char));
						s = prependString(s,  "return ");
						if($2 != 0)
							s = prependString(s,  $2->code);
						s = prependString(s,  " ; ");
						$2->code = s;
						$$ = $2;
						}
	;

jump_temp :
	/* empty */ { $$ = 0; }
	| expression { $$ = $1; }
	;


selection_statement : IF OP expression CP BEG stmts END {
								printf("//bison.y : inizion della if statement\n");
								char* s = calloc(1, sizeof(char));
								s = prependString(s,  "if (");
								s = prependString(s,  $3->code);
								s = prependString(s,  ") \n {");
								s = prependString(s,  $6->code);
								s = prependString(s,  "\n}\n");
								$3->code = s;
								$$ = $3;
								printf("//bison.y : fine della if statement\n");
							}
	| IF OP expression CP BEG stmts END ELSE BEG stmts END {
								char* s = calloc(1, sizeof(char));
								s = prependString(s,  "if (");
								s = prependString(s,  $3->code);
								s = prependString(s,  ") \n {");
								s = prependString(s,  $6);
								s = prependString(s,  "\n} else {\n");
								s = prependString(s,  $10->code);
								s = prependString(s,  "\n}\n");
								$3->code = s;
								$$ = $3;
								}
	;

iteration_statement : LOOP OP expression CP BEG stmts END {
								printf("//bison.y : inizio della loop statement\n");
								char* s = calloc(1, sizeof(char));
								s = prependString(s,  "while(");
								s = prependString(s,  $3->code);
								s = prependString(s,  ") {\n");
								s = prependString(s,  $6->code);
								s = prependString(s,  "\n}\n");
								$3->code = s;
								$$ = $3;
								printf("//bison.y : fine della loop statement\n");
							}
	;

assignment_statement : unary_expression assignment_operator expression SEMI_COLON { printf("//bison.y : Dentro l'assignment statement\n");
											if(strcmp($1->type, "unidentified") != 0 && strcmp($3->type, "unidentified") != 0)
												check_type($1,$3);
											copy_val($1,$3);
											printf("//bison.y : dopo copia del valore\n");
											char* s = calloc(1, sizeof(char));
											s = prependString(s,  $1->code);
											printf("//bison.y : dopo prima prepend\n");
											s = prependString(s,  " ");
											printf("//bison.y : dopo seconda prepend\n");
											s  = prependString(s , "=");
											printf("//bison.y : dopo terza prepend\n");
											s = prependString(s,  " ");
											s = prependString(s,  $3->code);
											s = prependString(s, ";\n");
											$1->code = s;
											$$ = $1;
											printf("//bison.y : fine dell'assignemnt statement\n");
										}
	| expression SEMI_COLON {
					printf("//bison.y : dentro la stmt formata da singola expression \n");
					char* s = calloc(1, sizeof(char));
					s = prependString(s,  $1->code);
					s = prependString(s,  " ; ");
					$1->code = s;
					$$ = $1;
					printf("//bison.y : fine della stmt formata da singola expression\n");
				}
	/* eliminata statements fatta da solo SEMI_COLON */
	;

object_statement : FREE OP IDENTIFIER CP SEMI_COLON {
							value* val;
							val = (value*) malloc(sizeof(value));
							val->name = strdup($3);
							//dealloco la memoria
							dealloc_mem(val);
							//codice della deallocazione
							char* s = calloc(1, sizeof(char));
							s = prependString(s,  "free(");
							s = prependString(s,  $3);
							s = prependString(s,  ") ;");
							val->code = s;
							$$ = val;
						    }
	| unary_expression ASSIGN  NEW OP IDENTIFIER CP SEMI_COLON {
									//debbo controllare che l'unary_expression sia dello stesso tipo
									//identificato dall'identifier
									printf("//bison.y : inizio dell'allocazione\n");
									value* temp;
									temp = (value*) malloc(sizeof(value));
									temp->type = strdup($5);
									printf("//bison.y : prima della check_type \n");
									printf("//bison.y : tipo da confrontare %s \n", temp->type);
									if(temp->type == 0) {
										printf("errore nell'assign \n");
										exit(1);
									}
									if(strcmp($1->type, temp->type) != 0) {
										printf("errore nel tipo dell'allocazione \n");
										exit(1);
									}
									check_type($1, temp);
									printf("//bison.y : dopo la check_type \n");
									//alloco memoria per il valore dell'unary_expression
									alloc_mem($1);
									//codice corrispondente all'allocazione di memoria
									printf("//bison.y : codice della unary %s\n", $1->code);
									char* s = generate_allocation_code($1, $5);
									$1->code = s;
									printf("//bison.y : dine dell'allocazione\n");
									$$ = $1;
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
				//printf("Lessema corrispondente al token: %s\n", rec->text);
				//printf("Tipo del lessema %s\n", rec->type);
			}
		}
	}
}
