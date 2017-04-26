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
//flag per la gestione del pop dell'environment
int shouldPop  = 0;

//funzione per lo swicht dell'environment ( scoping a blocchi del C)
void change_environment() {
	printf("//SM.h : inizio nuovo environment \n");
	sym_table* table  = (sym_table*) malloc(sizeof(sym_table));
	table->next = top;
	top = table;
	printf("//SM.h : fine nuovo environment \n");
}

//funzione per la chiusura dell'environment
void pop_environment() {
	sym_table* prev = top;
	sym_rec* entry = top->entries;
	struct sym_rec* temp;
	top = top->next;
	for(; entry != 0;) {
		temp = entry;
		entry = entry->next;
		free(temp);
	}
	free(prev);
	//ONLY FOR DEBUG 
	//if(top == 0) {
	//	top = calloc(1, sizeof(sym_table));
	//	top->entries = 0;
	//}
}

//aggiungo nuovo simbolo. Passo alla funzione puntatore a simbolo con campi gia' compilati
void insert_sym_rec(sym_rec* symbol) {
	printf("//SM.h : dentro la insert_sym_rec\n");
	printf("//SM.h : eloi eloi lema sabactani\n");
	printf("//SM.h : top->entries %p\n", top);
	if(top->entries != 0) {
		printf("//SM.h : top->entries != 0 \n");
		sym_rec* old = top->entries;
		printf("//SM.h : dopo salvataggio del vecchio valore\n");
		symbol->next = old;
	}
	top->entries = symbol;
}

//funzione per controllare l'esistenza di un simbolo nella symbol table ed eventualmente recuperarlo
sym_rec* get_sym_rec(char* name) {
	sym_table* table ;
	sym_rec* record;
	for(table = top; table != 0; table = table->next) {
		for(record = table->entries; record != 0; record = record->next) {
			//printf("Sto analizzando record %s\n", record->text);
			//printf("Cerco l'identificatore %s\n", name);
			if(strcmp(record->text, name)== 0) {
				return record;
			}
		}
	}

	return 0;
}

//funzione per controllare l'uguaglianza di due tipi
//implementa anche i controlli particolari per matrici e array
void check_type(value* val_1, value* val_2) {
	printf("//SM.h : dentro la check_type\n");
	//se sono esattamente lo stesso tipo
	if(strcmp(val_1->type, val_2->type) == 0) {
	}
	//altrimenti
	else {
		printf("//SM.h : confronto di tipi custom \n");
		//se sono dei tipi custom 
		if(is_base_type(val_1->type) !=1 && is_base_type(val_2->type) != 1) {
			printf("//SM.h : confronto di tipi custom \n");
			//recupero i record corrispondente ai due tipi custom
			sym_rec* type_1, *type_2;
			type_1 = get_sym_rec(val_1->type);
			type_2 = get_sym_rec(val_2->type);
			printf("//SM.h : tipi da confrontare %s %s \n", type_1->type, type_2->type);
			//se sono  array
			if(strcmp(type_1->type, "array") == 0 && strcmp(type_2->type, "array") == 0) {
				//recupero il conto dei dei parametri per i due tipi
				int count_1 = get_record_params_number(type_1);	
				int count_2 = get_record_params_number(type_2);
				//recupero il tipo dei parametri
				char* param_type_1 = type_1->param_type;
				char* param_type_2 = type_2->param_type;
				if(strcmp(param_type_1, param_type_2) == 0 && count_1 == count_2) {
					return;
				}
			}	
			printf("//SM.h : prima dell'if delle matrici \n");
			if(strcmp(type_1->type, "matrix") == 0 && strcmp(type_2->type, "matrix") == 0) {
				printf("//SM.h sto confrontando due matrici \n");
				//recupero il tipo dei parametri
				char* param_type_1 = type_1->param_type;
				char* param_type_2 = type_2->param_type;
				if(strcmp(param_type_1, param_type_2) == 0 ) {
					return;
				}
				
			}
		}
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
	//printf("Analizzo argomenti per la funzione %s\n", func_rec->text);
	//variabili temporanee per iterare su parametri e valori
	param* temp_par;
	value* temp_val;
	for(temp_par = func_rec->par_list, temp_val = args; temp_par != 0; temp_par = temp_par->next, temp_val = temp_val->next) {
		//printf("Analizzo l'argomento di nome (se c'e') %s\n", temp_val->name);
		//printf("Analizzo il parametro di nome (se c'e') %s\n", temp_par->name);
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
	//printf("valore del parametro dell'array %d\n", *((int*)(rec->current_param->val)));
	//printf("valore inserito %d\n", *((int*)(val->val)));
	if( *((int*)(val->val)) >= *((int*)(rec->current_param->val)) ) {
		printf("Indice oltre l'array\n");
		exit(1);
	}
	//sposto il current_param
	rec->current_param = rec->current_param->next;
}

void check_matrix_arguments(value* id, value* val_1, value* val_2) {
	printf("//SM.h : prima del recupero del symrec della matrice\n");
	//recupero il sym_rec corrispondente al tipo della matrice
	sym_rec* rec = get_sym_rec(id->type);
	printf("//SM.h : dopo il recupero del sym_rec\n");
	printf("//SM.h : %d\n", *((int*)(rec->current_param->val)));
	//controllo i due valori
	if(*((int*)(val_2->val)) >=  *((int*)(rec->current_param->val))) {
		printf("Indice oltre la matrice\n");
		exit(1);
	}
	//sposto il current_param
	printf("//SM.h : prima dello spostamento dl current_param\n");
	rec->current_param = rec->current_param->next;
	printf("//SM.h : dopo spostamento del current param\n");
	printf("//SM.h : %d\n", rec->current_param);
	//controllo il secondo parametro
	if(*((int*)(val_2->val)) >=  *((int*)(rec->current_param->val))) {
                printf("Indice oltre la matrice\n");
                exit(1);
        }
	printf("//SM.h : resetto i parametri della matrice\n");
	reset_current_param(id);
	printf("//SM.h : a fine check_matrix_arguments\n");
}

void reset_current_param(value* val) {
	//trovo il sym_rec
	printf("//SM.H : nome del value da resettare %s\n", val->name);
	printf("//SM.h : tipo %s \n", val->type);
	if(is_base_type(val->type) == 1) return;
	sym_rec* rec = get_sym_rec(val->type);
	if(rec != 0) {
		printf("//SM.h : sto resettando il parametro\n");
		rec->current_param = rec->par_list;
	}
}

void print_array_params(sym_rec* array) {
	//debbo stampare la lista par_list
	param* temp;
	for(temp = array->par_list; temp->next != 0; temp = temp->next) {
		//printf("sto stampando un parametro\n");
		//printf("valore del puntatore %p\n", temp);
		//printf("parametro di tipo %s\n", temp->name);
		//printf("Parametro di valore %d\n", *((int*)(temp->val)));
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
	//printf("record %s memoria %d\n", rec->text, rec->memoryAllocated);
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
			//printf("record di nome %s tipo %s\n", temp_rec->text, temp_rec->type);
			for(temp_param = temp_rec->par_list; temp_param != 0; temp_param = temp_param->next) {
				//cerco nella symbol table il record corrispondente al tipo del parametro
				//printf("cerco il tipo %s (nome %s) \n", temp_param->type, temp_param->name);
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
	//printf("//SM.h: all'inizio della check_recursive_definitions\n");
	sym_rec* temp_rec;
	param* temp_param;
	for(temp_rec = top->entries; (int)temp_rec != 0; temp_rec = temp_rec->next) {
		//se e' record corrispondente a typebuilder
		//printf("//SM.h: record in analisi nome: %s tipo: %s\n", temp_rec->text, temp_rec->type);
		if(is_recursive_type_builder(temp_rec->type)) {
			//printf("//SM.h: nome del record %s\n", temp_rec->text);
			//itero sui parametri e controllo che il tipo di ciascun parametro sia esistente
			for(temp_param = temp_rec->par_list; (int) temp_param != 0; temp_param = temp_param->next) {
				//printf("//SM.h: puntatore prossimo elemento %d\n", temp_param->next);
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
	//printf("ritorno dalla funzione check_recursive_definitions\n");
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
		//printf("prima del do while\n");
		do  {
			//printf("nome dell'identifier %s\n", temp->name);
			//recuper il nome e controllo che non sia un nome di funzione
			if(find_function_definition(temp->name) == 0) {
				//printf("dopo la find\n");
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
	//printf("prima del merge\n");
	merge_function_list();
	//printf("dopo merge\n");
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
			//printf("nome dell'identifier che confronto %s\n", temp->name);
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
	//printf("arrivato all'ultimo elemento della func_list_total\n");
	//aggiungo func_list come elemento successivo di temp
	if((int)(func_list) != 0) {
		if((int)(temp) != 0) {
			//printf("merge con lista esistente \n");
			temp->next = func_list;
		}
		else {
			//printf("merge con lista nuova\n");
			func_list_total = func_list;
		}
	}
}

//funzione che imposta la prima stringa come prefisso della seconda
char* prependString(char* dst, char* source) {
	//calcolo la lunghezza totale della stringa di destinazione
	int length = strlen(dst)+strlen(source)+2;
	dst = realloc(dst, length*sizeof(char));
	dst = strcat(dst, source);
	return dst;
}

char* insert_after_struct(char* dst, char* toInsert) {
	//recupero la prima occorrenza di struct
	char* structPosition = strstr(dst, "struct");
	//alloco lo spazio necessario alla stringa risultante
	int length = strlen(dst)+strlen(toInsert)+2;
	char* res = calloc(length, sizeof(char));
	//inizializzo la prima parte della stringa
	strcpy(res, "typedef struct ");
	//aggiungo il nome della struct
	res = prependString(res,  toInsert);
	//aggiungo il resto dell struct
	res = prependString(res,  structPosition+6);
	//ritorno la stringa appena creata
	return res;
}

//funzione per la ricorsione necessaria all'allocazione di un array
char* recursive_array_allocation(char* qualifiedId, param* par_list, char* type) {
	//caso base
	//printf("//SM.h : dentro la recursive_array_allocation\n");
	if(par_list->next == 0) {
		char* temp = calloc(1, sizeof(char));
		return temp;
	}
	//prendo la size della dimensione attuale
	int count = *((int*)(par_list->val));
	//size della dimensione successiva
	int toAlloc = *((int*)(par_list->next->val));
	//printf("//SM.h : prima  dell'allocazione dello spazio per s_temp\n");
	char* s_temp = calloc(10, sizeof(char));
	//printf("//SM.h : dopo allocazione di s_temp\n");
	char *s;
	s = (char*)calloc(1, sizeof(char));
	//printf("//SM.h : dopo allocazione di s\n");
	char *s_next;
	//printf("//SM.h : dopo allocazione di s_next\n");
	int i = 0;
	for(i = 0; i < count; i++) {
		//creo il pezzo di output
		//printf("//SM.h : prima della creazione del qualified identifier\n");
		sprintf(s_temp, "%s[%d]", qualifiedId, i);
		//printf("//SM.h : dopo la creazione del qualified identifier\n");
		s = prependString(s,  s_temp);
		s = prependString(s,  " = calloc(");
		sprintf(s_temp, "%d", toAlloc);
		s = prependString(s,  s_temp);
		s = prependString(s, ", sizeof(");
		//alloco puntatori fino all'ultima passata
		if(par_list->next->next == 0)
			s = prependString(s,  type);
		else
			s = prependString(s, "void*");
		s = prependString(s,  "));\n");
		//ricreo il qualifier da passare
		sprintf(s_temp, "%s[%d]", qualifiedId, i);
		//chiamata ricorsiva
		s_next = recursive_array_allocation(s_temp, par_list->next, type);
		s = prependString(s,  s_next);
	}

	return s;
}

char* output_allocation_code_matrix(char* variable, char* type) {
	char* s = calloc(1, sizeof(char));
	//recupero il sym_rec del tipo
	sym_rec* temp = get_sym_rec(type);
	//flag per tipo int o double della matrice
	int flag;
	if(strcmp(temp->param_type, "integer") == 0) {
		flag = 0;
	}
	else {
		flag = 1;
	}
	//recupero il numero delle righe
	param* temp_param = temp->par_list;
	int rows = *((int*)(temp_param->val));
	//alloco lo spazio per le righe
	s = prependString(s,  variable);
	s = prependString(s,  " = ");
	s = prependString(s,  "calloc(");
	char* s_temp = calloc(1, sizeof(char));
	sprintf(s_temp, "%d", rows);
	s = prependString(s,  s_temp);
	s = prependString(s, ", sizeof(");
	s = prependString(s, "void*));\n");
	//if(flag == 0)
	//	prependString(s, "int));\n");
	//else
	//	s = prependString(s,  "double));\n");
	//alloco lo spazio per le colonne, recuperando il numero delle colonne
	temp_param = temp_param->next;
	int cols = *((int*)(temp_param->val));
	char* ind = calloc(10, sizeof(char));
	sprintf(s_temp, "%d", cols);
	//itero sulle righe
	int i_temp;
	for(i_temp = 0; i_temp < rows; i_temp++) {
		sprintf(ind, "%d", i_temp);
		s = prependString(s,  variable);
		s = prependString(s,  "[");
		s = prependString(s,  ind);
		s = prependString(s,  "] = calloc(");
		s = prependString(s,  s_temp);
		s = prependString(s, ", sizeof(");
		if(flag == 0)
			s = prependString(s,  "int));\n");
		else
			s = prependString(s,  "double));\n");
	}
	//ritorno s
	return s;
}

char* output_allocation_code_array(char* variable, char* type) {
	char* s = calloc(1, sizeof(char));
	char* s_temp = calloc(10, sizeof(char));
	//recupero il sym_rec corrispondente al tipo
	sym_rec* temp = get_sym_rec(type);
	//flag per tipo int o double della matrice
	char* typeToPass;
	if(strcmp(temp->param_type, "integer") == 0 || strcmp(temp->param_type, "boolean") == 0) {
		typeToPass = "int";
	}
	else if(strcmp(temp->param_type, "floating") == 0) {
		typeToPass = "double";
	}
	else {
		typeToPass = strdup(temp->param_type);
	}
	//prima allocazione dell'array
	param* temp_param = temp->par_list;
	int count = *((int*)(temp_param->val));
	s = prependString(s,  variable);
	s = prependString(s,  " = calloc(");
	sprintf(s_temp, "%d", count);
	s = prependString(s,  s_temp);
	s = prependString(s, ", sizeof(");
	if(temp_param->next == 0)
		s = prependString(s,  typeToPass);
	else
		s = prependString(s, "void*");
	s = prependString(s,  "));\n");
	//chiamata alla funzione che allochera' il resto dell'array
	if(temp_param->next != 0) {
		char* s_rec;
		s_rec = recursive_array_allocation(variable, temp_param, typeToPass);
		s = prependString(s, s_rec);
	}
	return s;


}

char* generate_allocation_code(value* val, char* type) {
	//recupero il record corrispondente alla variabile
	//printf("//SM.h : dentro la generate_allocation_code\n");
	sym_rec* temp = get_sym_rec(type);
	char* s = calloc(1, sizeof(char));
	//printf("//SM.h : tipo della variabile che si sta allocando %s \n", temp->type);
	//controllo il tipo
	if(strcmp(temp->type, "record") == 0) {
		//printf("//SM.h : dentro la sezione della generate_allocation_code relativa ai record\n");
		s = prependString(s,  val->name);
		s = prependString(s,  " = ");
		s = prependString(s, "calloc(1, sizeof(");
		s = prependString(s, type);
		s = prependString(s, "));\n");
	}
	else if(strcmp(temp->type, "matrix") == 0) {
		//richiamo funzione specifica per allocazione della matrice
		s = output_allocation_code_matrix(val->code, type);
	}
	else {
		//richiamo funzione specifica per allocazione dell'array
		s = output_allocation_code_array(val->code, type);
	}
	return s;

}

//function to escape percent in string
char* escape_percent(char* string) {
	printf("//SM.h : inizio della escape_percent\n");
	//loop the string escaping percent
	char c = string[0];
	int i_old = 0;
	int i_new = 0;
	int countRealloc = 0;
	//new string to be returned
	char* s = calloc(strlen(string)+1, sizeof(char));
	while(c != '\0') {
		c = string[i_old];
		printf("//SM.h : carattere che sto leggento %c\n", c);
		if(c == '\"') {
			i_old++;
			continue;
		}
		//if character is %
		if(c == '%') {
			printf("//SM.h : sto leggendo percent \n");
			countRealloc++;
			s = realloc(s, strlen(string)+1+countRealloc);
			s[i_new] = '%';
			printf("//SM.h : carattere che sto scrivendo %c\n", s[i_new]);
			s[i_new+1] = c;
			printf("//SM.h : carattere che sto scrivendo %c\n",s[i_new+1]);
			i_new++;
		}
		else {
			s[i_new] = c;
			printf("//SM.h : carattere che sto scrivendo %c\n", s[i_new]);
		}
		i_old++;
		i_new++;
	}
	s[i_new] = '\0';
	printf("//SM.h : stringa dopo la escape_percent %s\n", s );
	printf("//SM.h : fine della escape_percent\n");

	return s;
}

//function to get number of parameters from a symbol record
int get_record_params_number(sym_rec* rec) {
	//initialize counter and seeker
	int count = 1;
	param* temp = rec->par_list;
	while(temp->next != 0) {
		count++;
		temp = temp->next;
	}
	return count;
}
