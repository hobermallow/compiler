//includo il file per le definizioni di tipo
#include "type_definitions.h"


#define INVERT_PARAM_LIST(root)  { param *x, *z, *y; y = root;  while(root != 0) { z = root->next; root->next = x; x = root; root = z; }y->next= 0; root = x;}

//variabile globale contenente il riferimento alla symbol_table
sym_table* top;
//variabile globale per lista temporanea delle funzioni utilizzate all'interno della definizione di ciascuna funzione
func* func_list;
//variabile globale che tiene conto di tutte le funzioni utilizzate all'interno delle definizioni di funzione
func* func_list_total;
//variabile globalle per la lista di identificatori utilizzati all'interno delle definizioni di funzione
func* identifier_list;
//variabile per escludere dal normale controllo sugli identificatori di funzione la sezione deditcata alla definizioni di funzioni
int functionDefinitions = 0;

//funzione per lo swicht dell'environment ( scoping a blocchi del C)
void change_environment() {
	sym_table* table  = (sym_table*) malloc(sizeof(sym_table));
	table->next = top;
	top = table;
}

//funzione per la chiusura dell'environment
void pop_environment() {
	top = top->next;
}

//aggiungo nuovo simbolo. Passo alla funzione puntatore a simbolo con campi gia' compilati
void insert_sym_rec(sym_rec* symbol) {
	sym_rec* old = top->entries;
	symbol->next = old;
	top->entries = symbol;
}

//funzione per controllare l'esistenza di un simbolo nella symbol table ed eventualmente recuperarlo
sym_rec* get_sym_rec(char* name) {
	sym_table* table ;
	sym_rec* record;
	for(table = top; table != 0; table = table->next) {
		for(record = table->entries; record != 0; record = record->next) {
			printf("Sto analizzando record %s\n", record->text);
			printf("Cerco l'identificatore %s\n", name);
			if(strcmp(record->text, name)== 0) {
				return record;
			}
		}
	}

	return 0;
}

//funzione per controllare l'uguaglianza di due tipi
void check_type(value* val_1, value* val_2) {
	if(strcmp(val_1->type, val_2->type) == 0) {
	}
	else {
		printf("%s tipo diverso da %s\n", val_1->type, val_2->type);
		exit(1);
	}
}

//confronto fra due valori , da utilizzare dopo funzione precedente
int check_equal(value* val_1, value* val_2) {

	if(strcmp(val_1->type, "integer") == 0 ) {
		return *((int*)(val_1->val)) == *((int*)(val_2->val));
	}

	if(strcmp(val_1->type, "floating") == 0 ) {
		return *((double*)(val_1->val)) == *((double*)(val_2->val));
	}

	if(strcmp(val_1->type, "string") == 0 ) {
		return strcmp(val_1->val, val_2->val) == 0;
	}

	if(strcmp(val_1->type, "char") == 0 ) {
		return strcmp(val_1->val, val_2->val) == 0;
	}

	if(strcmp(val_1->type, "boolean") == 0) {
		return *((int*)(val_1->val)) == *((int*)(val_2->val));
	}
}

//somma di due tipi base

void add_base_type(int op, value* val_1, value* val_2, value* temp) {

	if(strcmp("integer", val_1->type) == 0 ) {
		//sommo due interi
		temp->val = (int*) malloc(sizeof(int));
		if(op == 0)
			*((int*)(temp->val)) = *((int*)(val_1->val)) + *((int*)(val_2->val));
		else
			*((int*)(temp->val)) = *((int*)(val_1->val)) - *((int*)(val_2->val));
		temp->type = "integer";
	}

	if(strcmp("floating", val_1->type) == 0 ) {
		//sommo due interi
		temp->val = (double*) malloc(sizeof(double));
		if(op == 0)
			*((double*)(temp->val)) = *((double*)(val_1->val)) + *((double*)(val_2->val));
		else
			*((double*)(temp->val)) = *((double*)(val_1->val)) - *((double*)(val_2->val));
		temp->type = "floating";
	}
}

//moltiplicazione di due tipi base

void mul_base_type(int op, value* val_1, value* val_2, value* temp) {

	if(strcmp("integer", val_1->type) == 0 ) {
		//sommo due interi
		temp->val = (int*) malloc(sizeof(int));
		if(op == 0)
			*((int*)(temp->val)) = *((int*)(val_1->val)) * *((int*)(val_2->val));
		else
			*((int*)(temp->val)) = *((int*)(val_1->val)) / *((int*)(val_2->val));
		temp->type = "integer";
	}

	if(strcmp("floating", val_1->type) == 0 ) {
		//sommo due interi
		temp->val = (double*) malloc(sizeof(double));
		if(op == 0)
			*((double*)(temp->val)) = *((double*)(val_1->val)) * *((double*)(val_2->val));
		else
			*((double*)(temp->val)) = *((double*)(val_1->val)) / *((double*)(val_2->val));
		temp->type = "floating";
	}
}

void exp_base_type(value* val_1, value* temp) {

	if(strcmp("integer", val_1->type) == 0 ) {
		if(*((int*)(val_1->val)) == 0) {
			*((int*)(temp->val)) =  1;
		}
		else {
			int t = 1;
			int i = 0;
			for(i = 0; i < *((int*)(val_1->val)); i++) {
				t *= *((int*)(temp->val));
			}
			*((int*)(temp->val)) = t;
		}
	}

}

void initialize_value(sym_rec* rec) {
	if(strcmp("integer", rec->type) == 0) {
		rec->val = (int*) malloc(sizeof(int));
		*((int*)(rec->val)) = 0;
	}
	if(strcmp("floating", rec->type) == 0) {
		rec->val = (double*) malloc(sizeof(double));
		*((double*)(rec->val)) = 0;
	}

	if(strcmp("char", rec->type) == 0) {
		rec->val = strdup("");
	}

	if(strcmp("string", rec->type) == 0) {
		rec->val = strdup("");
	}
	if(strcmp("boolean", rec->type) == 0) {
		rec->val = (int*) malloc(sizeof(int));
		*((int*)(rec->val)) = 0;
	}
}

void check_is_integer(value* val) {
	if(strcmp("integer", val->type) != 0) {
		printf("Errore nel cast esplicito\n");
		exit(1);
	}
}

void copy_val(value* dst, value* src) {
	if(strcmp(src->type, "integer") == 0) {
		dst->val = (int*) malloc(sizeof(int));
		*((int*)(dst->val)) = *((int*)(src->val));
	}
	if(strcmp(src->type, "floating") == 0) {
		dst->val = (double*) malloc(sizeof(double));
		*((double*)(dst->val)) = *((double*)(src->val));
	}
}
void change_sign(value* init) {
	if(strcmp(init->type, "integer") == 0) {
		*((int*)(init->val)) =  *((int*)(init->val))*(-1);
	}
	if(strcmp(init->type, "floating") == 0) {
		*((double*)(init->val)) =  *((double*)(init->val))*(-1);
	}
}


void check_function_arguments(value* func, value* args) {
	//recupero il record corrispondente alla funzione
	sym_rec* func_rec = get_sym_rec(func->name);
	//debug
	printf("Analizzo argomenti per la funzione %s\n", func_rec->text);
	//variabili temporanee per iterare su parametri e valori
	param* temp_par;
	value* temp_val;
	for(temp_par = func_rec->par_list, temp_val = args; temp_par != 0; temp_par = temp_par->next, temp_val = temp_val->next) {
		printf("Analizzo l'argomento di nome (se c'e') %s\n", temp_val->name);
		printf("Analizzo il parametro di nome (se c'e') %s\n", temp_par->name);
		//se l'argomento e' nullo, errore (manca argomento)
		if(temp_val == 0) {
			printf("Numero argomenti inseriti minore di quello richiesto dalla funzione\n");
			exit(1);
		}
		//altrimenti, controllo che i tipi corrispondano
		if(strcmp(temp_val->type, temp_par->type) != 0) {
			printf("Errore negli  argomenti passati alla funzione\n");
			exit(1);
		}
	}
	//se temp_val e' diverso da 0, ho inserito almeno un argomento in piu'
	if(temp_val != 0) {
		printf("Numero argomenti inseriti maggiore di quelli richiesti dalla funzione\n");
		exit(1);
	}
}
void copy_val_in_param(param* dst, value* src) {
	if(strcmp(src->type, "integer") == 0) {
		dst->val = malloc(sizeof(int));
		*((int*)(dst->val)) = *((int*)(src->val));
	}
	if(strcmp(src->type, "floating") == 0) {
		dst->val = malloc(sizeof(double));
		*((double*)(dst->val)) = *((double*)(src->val));
	}
}

void check_array_arguments(value* id, value* val) {
	//recupero il sym_rec corrispondente al tipo dell'array
	sym_rec* rec = get_sym_rec(id->type);
	//controllo con current_param, di cui dereferenzio il valore con int
	//DEBUG
	printf("valore del parametro dell'array %d\n", *((int*)(rec->current_param->val)));
	printf("valore inserito %d\n", *((int*)(val->val)));
	if( *((int*)(val->val)) >= *((int*)(rec->current_param->val)) ) {
		printf("Indice oltre l'array\n");
		exit(1);
	}
	//sposto il current_param
	rec->current_param = rec->current_param->next;
}

void check_matrix_arguments(value* id, value* val_1, value* val_2) {
	printf("prima del recupero del symrec della matrice\n");
	//recupero il sym_rec corrispondente al tipo della matrice
	sym_rec* rec = get_sym_rec(id->type);
	//controllo i due valori
	if(*((int*)(val_1->val)) >=  *((int*)(rec->current_param->val))) {
		printf("Indice oltre la matrice\n");
		exit(1);
	}
	//sposto il current_param
	rec->current_param = rec->current_param->next;
	//controllo il secondo parametro
	if(*((int*)(val_2->val)) >=  *((int*)(rec->current_param->val))) {
                printf("Indice oltre la matrice\n");
                exit(1);
        }
}

void reset_current_param(value* val) {
	//trovo il sym_rec
	sym_rec* rec = get_sym_rec(val->type);
	if(rec != 0)
		rec->current_param = rec->par_list;
}

void print_array_params(sym_rec* array) {
	//debbo stampare la lista par_list
	param* temp;
	for(temp = array->par_list; temp->next != 0; temp = temp->next) {
		printf("sto stampando un parametro\n");
		printf("valore del puntatore %p\n", temp);
		printf("parametro di tipo %s\n", temp->name);
		printf("Parametro di valore %d\n", *((int*)(temp->val)));
	}
}

void check_record_arguments(value* record, char* field) {
	//debbo controllare che il field sia contenuto all'interno del record
	//recupero il record corrispondente al tipo di record
	sym_rec* rec = get_sym_rec(record->type);
	//itero sui parametri del record, cercando l'identificatore
	param* temp;
	for(temp = rec->par_list; temp != 0; temp = temp->next) {
		//compare del nome del parametro con la stringa passata come argomento
		if(strcmp(temp->name, field)== 0) {
			return;
		}
	}
	//se arrivo a questo punto, vuol dire che non ho trovato il record
	exit(1);
}

void check_mem_alloc(value* val) {
	//recupero il record corrispondente alla variabile
	sym_rec* rec = get_sym_rec(val->name);
	printf("record %s memoria %d\n", rec->text, rec->memoryAllocated);
	//controllo l'allocazione
	if(rec->memoryAllocated == 0) {
		printf("Memoria per la variabile non allocata\n");
		exit(1);
	}
}

int is_base_type(char* type) {
	if(strcmp(type, "integer") == 0) {
		return 1;
	}
	else if(strcmp(type, "floating") == 0) {
		return 1;
	}
	else if(strcmp(type, "boolean") == 0){
		return 1;
	}
	else if(strcmp(type, "char") == 0) {
		return 1;
	}
	else if(strcmp(type, "string") == 0) {
		return 1;
	}
	return 0;
}

void alloc_mem(value* val) {
	sym_rec* rec = get_sym_rec(val->name);
	//alloco la memoria
	rec->memoryAllocated = 1;
}

void dealloc_mem(value* val) {
	sym_rec* rec = get_sym_rec(val->name);
	rec->memoryAllocated = 0;
}

void check_type_definitions() {
	//metodo da ottimizzare assolutamente
	sym_table* temp_table;
	sym_rec* temp_rec;
	param* temp_param;
	for(temp_table = top; temp_table != 0; temp_table = temp_table->next) {
		for(temp_rec = top->entries; temp_rec != 0; temp_rec = temp_rec->next) {
			//dovrei essere sicuro , al momento dell'invocazione della funzione, che i record presenti corrispondono solamente a
			//dichiarazioni di tipo
			//DEBUG
			printf("record di nome %s tipo %s\n", temp_rec->text, temp_rec->type);
			for(temp_param = temp_rec->par_list; temp_param != 0; temp_param = temp_param->next) {
				//cerco nella symbol table il record corrispondente al tipo del parametro
				printf("cerco il tipo %s (nome %s) \n", temp_param->type, temp_param->name);
				if(is_base_type(temp_param->type)) continue;	
				if(get_sym_rec(temp_param->type) == 0) {
					printf("Tipo non trovato: %s\n", temp_param->type);
					exit(1);
				}
			}

		}
	}
}

//funzione per recuperare il field di un record
value* get_record_field(value* record, char* field) {
	//recupero il record corrispondente al record
	sym_rec* rec = (sym_rec*) get_sym_rec(record->type);
	//cerco il field specifico
	param* ret;
	for(ret = rec->par_list; ret != 0; ret = ret->next) {
		if(strcmp(ret->name, field) == 0) {
			//ho trovato il valore
			break;
		}
	}
	//creo il nuovo value
	value* temp = (value*) malloc(sizeof(value));
	temp->name = strdup(ret->name);
	temp->type = strdup(ret->type);
	return temp;
}


//funzione che controlla l'esistenza di tutti i tipi utilizzati nelle
//definizioni di tipo
int check_recursive_definitions() {
	//a partire dalla symbol table, per ogni record di tipo
	//array, matrice o record , controlla la lista dei parametri, cercando
	//per ciascun tipo custom il corrispondente record nella symbol table
	printf("//SM.h: all'inizio della check_recursive_definitions\n");
	sym_rec* temp_rec;
	param* temp_param;
	for(temp_rec = top->entries; (int)temp_rec != 0; temp_rec = temp_rec->next) {
		//se e' record corrispondente a typebuilder
		printf("//SM.h: record in analisi nome: %s tipo: %s\n", temp_rec->text, temp_rec->type);
		if(is_recursive_type_builder(temp_rec->type)) {
			printf("//SM.h: nome del record %s\n", temp_rec->text);
			//itero sui parametri e controllo che il tipo di ciascun parametro sia esistente
			for(temp_param = temp_rec->par_list; (int) temp_param != 0; temp_param = temp_param->next) {
				printf("//SM.h: puntatore prossimo elemento %d\n", temp_param->next);
				//controllo che esista un record corrispondente al tipo del parametro se non e' base type
				if(is_base_type(temp_param->type) == 0) {
					//cerco il record corrispondente al tipo del parametro
					sym_rec* aaaa =get_sym_rec(temp_param->type);
					if((int)aaaa == 0) {
						return 0;
					}
				}
			}
		}


	}
	printf("ritorno dalla funzione check_recursive_definitions\n");
	return 1;
}

//utility per controllare che una stringa di tipo indichi un record corrispondente ad un typebuilder
int is_recursive_type_builder(char* type) {
	if(strcmp(type, "array")==0) {
		return 1;
	}
	if(strcmp(type, "record")==0) {
		return 1;
	}
	return 0;
}

void check_param_list_base_type(param* list) {
	//controllo il primo elemento
	if((int)list != 0) {
		if(is_base_type(list->type) == 0) {
			printf("Parametro non di tipo base nelle funzione exec\n");
			exit(1);
		}
		else {
			for(list = list->next; list != 0; list = list->next) {
				if(is_base_type(list->type) == 0) {
					printf("Parametro non di tipo base nella funzione exec\n");
					exit(1);
				}
			}
		}
	}
}

//funzione per controllare che tutti gli identificatori non di funzione utilizzati all'interno
//di una definizione di funzione siano stati dichiarati
void check_function_definition_identifiers() {
	//itero sulla lista degli identificatori
	func* temp;
	temp = identifier_list;
	//se la lista non e' vuota
	if((int)(temp) != 0) {
		printf("prima del do while\n");
		do  {
			printf("nome dell'identifier %s\n", temp->name);
			//recuper il nome e controllo che non sia un nome di funzione
			if(find_function_definition(temp->name) == 0) {
				printf("dopo la find\n");
				//non e' una funzione, dunque cerco il record corrispondente nella symbol table
				//se non viene trovato, la funzione get_sym_rec interrompe l'esecuzione
				sym_rec* rec = get_sym_rec(temp->name);
				if((int)(rec) == 0) {
					printf("Identificatore %s non dichiarato\n", temp->name);
					exit(1);
				}
			}
			temp = temp->next;
		}
		while((int)(temp) != 0);
	}
	//merge delle liste degli utilizzi di funzione
	printf("prima del merge\n");
	merge_function_list();
	printf("dopo merge\n");
	//debbo reinizializzare la lista degli identificatori e quella temporanea delle funzioni
	identifier_list = 0;
	func_list = 0;
}

int find_function_definition(char* name) {
	//itero sulla lista delle funzioni utilizzate  nelle dichiarazioni di funzione
	func* temp;
	temp = func_list;
	if((int)(temp) != 0) {
		do {
			printf("nome dell'identifier che confronto %s\n", temp->name);
			//verifico che il nome della funzione sia lo stesso di quello passato come argomento
			if(strcmp(name, temp->name) == 0) {
				return 1;
			}
			temp = temp->next;
		}
		while((int)(temp) != 0);
	}
	//se non trovo nulla, ritorno 0
	return 0;
}

void merge_function_list() {
	//debbo aggiunger func_list in fondo a func_list_total
	//recupero l'ultimo elemento di func_list_global
	func* temp;
	temp = func_list_total;
		if((int)(temp) != 0) {
		while ((int)(temp->next) != 0) {

			temp = temp->next;
		}
	}
	printf("arrivato all'ultimo elemento della func_list_total\n");
	//aggiungo func_list come elemento successivo di temp
	if((int)(func_list) != 0) {
		if((int)(temp) != 0) {
			printf("merge con lista esistente \n");
			temp->next = func_list;
		}
		else {
			printf("merge con lista nuova\n");
			func_list_total = func_list;
		}
	}
}

//funzione che imposta la prima stringa come prefisso della seconda
char* prependString(char* first, char* second) {
	//wrapper per concat
	char* temp;
	temp = strcat(first, second);
	return temp;
}

//funzione che imposta la prima stringa come suffisso della seconda
char* appendString(char* first, char* second) {
	char* temp;
	temp = strcat(second, first);
	return temp;
}

char* insert_after_struct(char* dst, char* toInsert) {
	printf("//SM.h : stringa sorgente insert_after_struct %s\n", dst);
	printf("//SM.h : stringa  da inserire insert_after_struct %s\n", toInsert);
	//recupero la prima occorrenza di struct
	char* structPosition = strstr(dst, "struct");
	printf("//SM.h : porca madonna puttana %s %s \n" , dst, structPosition);
	printf("//SM.h : dio canaja de dio %s\n", structPosition);
	//creo la stringa temporanea da ritornare
	char* temp = calloc(strlen(dst), sizeof(char));
	printf("//SM.h : insert_after_struct temp %s\n", temp);
	printf("//SM.h : dio canaja de dio %s\n", structPosition);
	//inizializzo la stringa con typedef struct
	strcat(temp, "typedef struct ");
	printf("//SM.h : dio canaja de dio %s\n", structPosition);
	printf("//SM.h : insert_after_struct temp %s\n", temp);
	//appendo la stringa toInsert
	strcat(temp, toInsert);
	printf("//SM.h : dio canaja de dio %s\n", structPosition);
	printf("//SM.h : insert_after_struct temp %s\n", temp);
	//appendo il resto della stringa originale
	printf("//SM.h : dio canaja de dio %s\n", structPosition);
	strcat(temp, (structPosition+6));
	//ritorno la stringa creata
	printf("//SM.h : porco dio ladro %s \n" , temp);
	return temp;
}
