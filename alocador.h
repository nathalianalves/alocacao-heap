// Inicializa as variáveis globais utilizadas pelo alocador
void iniciaAlocador();  

// Restaura a versão original (antes de iniciaAlocador()) da heap
void finalizaAlocador(); 

// Libera o bloco passado como parametro
void liberaMem(void* bloco); 

// Aloca o número de bytes passado como parametro
void* alocaMem(int num_bytes); 

/* Imprime um mapa da heap seguindo a seguinte configuração para cada bloco:
 * Bytes gerenciais: representados por '#'
 * Bytes usáveis: representados por '+' (se bloco estiver ocupado) ou '-' (se bloco estiver livre)
 */
void imprimeMapa();     