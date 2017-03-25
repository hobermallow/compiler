#ifndef __TYPE_DEFINITIONS.H__
#define __TYPE_DEFINITIONS.H__
//struttura per la gestione di parametri (di funzione, di array, di matrici )
typedef struct param param;

struct param {
        param* next;
        char* name;
        char* type;
        void* val;
} ;

//struttura per la gestione della definizione di funzioni mututamente ricorsive
typedef struct func func;

struct func {
        char* name;
        struct func* next;
};
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
        char* custom_type;
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
        //variabile per l'operando di eventuale overload
        char* operand;
};


//symbol table
typedef struct sym_table sym_table ;

struct sym_table {
        sym_table* next;
        sym_rec* entries;
} ;

#endif
