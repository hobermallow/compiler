#define INVERT_PARAM_LIST(root)  { param *x, *z;  while(root != 0) { z = root->next; root->next = x; x = root; root = z; } root = x;}
	
//struttura per la gestione di parametri (di funzione, di array, di matrici )
typedef struct param param;

struct param {
	param* next;
	char* name;
	char* type;
	void* val;
} ;
//struttura per la gestione di un nuovo tipo 
typedef struct new_type new_type;

struct new_type {
	char* type;
	param* par_list;
};
//struttura per un valore
typedef struct value value;

struct value {
	char* type;
	char* name;
	void* val;
	value* next;
};
//record della symbol table
typedef struct sym_rec sym_rec;

struct sym_rec {
	char* text;
	char* type;
	void* val;
	param* par_list;
	char* param_type;
	//hacking
	//parametro temporaneo che punta all'elemento in esame della par_list
	param* current_param;
	sym_rec* next;
	//doppio hack
	//parametro int per info su inizializzazione record
	//le variabili di tipo custom vanno inizializzate
	int memoryAllocated;
};


//symbol table
typedef struct sym_table sym_table ;

struct sym_table {
	sym_table* next;
	sym_rec* entries;
} ;

sym_table* top;

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
	if(strcmp(dst->type, "integer") == 0) {
		*((int*)(dst->val)) = *((int*)(src->val));
	}
	if(strcmp(dst->type, "floating") == 0) {
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
	for(temp = array->par_list; temp != 0; temp = temp->next) {
		printf("Parametro di valore %d\n", *((int*)(temp->val)) );
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
			  
