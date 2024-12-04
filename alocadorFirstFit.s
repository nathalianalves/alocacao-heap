.section .data
	BRK: .quad 0
	TOPO_INICIAL_HEAP: .quad 0
	TOPO_ATUAL_HEAP: .quad 0
	STRING_GERENCIAL: .string "################"
	CHAR_LIVRE: .string "-"
	CHAR_OCUPADO: .string "+"
	
.section .text 

# Configura as variaveis globais utilizadas para coordenar a heap
.globl iniciaAlocador
.type iniciaAlocador, @function
iniciaAlocador:
	pushq %rbp
	movq %rsp, %rbp

	# Armazena o brk atual em %rax
	movq $12, %rax
	movq $0, %rdi
	syscall

	# Antes de qualquer alocação, BRK = TOPO_INICIAL_HEAP = TOPO_ATUAL_HEAP
	movq %rax, BRK
	movq %rax, TOPO_INICIAL_HEAP
	movq %rax, TOPO_ATUAL_HEAP
	
	popq %rbp
	ret

# Restaura o brk para o inicial
.globl finalizaAlocador
.type finalizaAlocador, @function
finalizaAlocador:
	pushq %rbp
	movq %rsp, %rbp

	# Restaura o brk para o que era antes de qualquer alocação e atualiza TOPO_ATUAL_HEAP e BRK
	movq $12, %rax
	movq TOPO_INICIAL_HEAP, %rdi
	movq %rdi, TOPO_ATUAL_HEAP
	movq %rdi, BRK
	syscall

	popq %rbp
	ret 

# Desaloca (invalida) o bloco de memoria passado em %rdi
 .globl liberaMem
 .type liberaMem, @function
 liberaMem:
	pushq %rbp
	movq %rsp, %rbp

	movq %rdi, %rax # Armazena o endereço do bloco a ser liberado em %rax
	subq $16, %rax # Subtrai 16 do endereço, para acessar o byte de válido, e armazena em %rax
	movq $0, (%rax) # Muda o byte de válido para 0

	call removeSequencias 
	call removeSequencias

	popq %rbp
	ret

# Se existir mais de um bloco inválido em sequência, junta todos em um só
removeSequencias:
	pushq %rbp
	movq %rsp, %rbp

	# %rdi armazena o topo inicial da heap
	movq TOPO_INICIAL_HEAP, %rdi
	jmp whileRemoveSeq

	proximoBlocoRemoveSeq:
	# se chegou ao final da heap, finaliza a funcao
	cmpq %rdi, TOPO_ATUAL_HEAP
	jle fimRemoveSeq

	movq %rdi, %r14 
	addq $8, %r14 # r14 := endereço que guarda o tamanho do bloco atual
	movq (%r14), %r10 # r10 := tamanho do bloco atual
	addq $16, %rdi # rdi := endereço de inicio dos bytes de armazenamento do bloco atual
	addq %r10, %rdi # rdi := informações gerenciais do proximo bloco
	
	cmpq %rdi, TOPO_ATUAL_HEAP
	jle fimRemoveSeq

	whileRemoveSeq:
	# se o bloco atual é valido, faz rdi pular para o proximo bloco livre
	movq (%rdi), %r14
	cmpq $1, %r14 
	je proximoBlocoRemoveSeq 

	juncaoRemoveSeq:
	movq %rdi, %rax # rax := inicio do bloco
	addq $8, %rax # rax := endereço do byte que armazena o tamanho do bloco
	movq (%rax), %r10 # r10 := tamanho do bloco

	movq %rdi, %r11 # r11 := inicio do bloco
	addq $16, %r11 # r11 := inicio das informações do bloco (pula as informações gerenciais)
	addq %r10, %r11 # r11 := inicio do proximo bloco

	# se chegou no final da heap, finaliza a funcao
	cmpq %r11, TOPO_ATUAL_HEAP
	jle fimRemoveSeq 

	movq (%r11), %r12 # r12 := conteudo da primeira informação gerencial do proximo bloco (valido ou nao)
	cmpq $1, %r12
	je proximoBlocoRemoveSeq # se o proximo bloco é valido, junta os invalidos 

	addq $8, %r11 # r11 := endereço do tamanho do proximo bloco
	movq (%r11), %r13 # r13 := tamanho do proximo bloco

	movq %rdi, %r11
	addq $8, %r11 # r11 := endereço do tamanho do primeiro bloco
	addq %r13, (%r11) # r11 := tamanho do primeiro bloco + tamanho do segundo bloco
	addq $16, (%r11) # r11 := tamanho do primeiro bloco + tamanho do segundo bloco + 16 bytes (q estavam sendo usados para informação gerencial do segundo bloco e nao estao mais)

	fimRemoveSeq:
	popq %rbp
	ret

# Aloca bytes
# Mapeamento das variáveis locais:
#	-8(%rbp) := nodoAtual 
#	-16(%rbp) := firstFit
#	-24(%rbp) := achouFirstFit
#	-32(%rbp) := numBytes
#	-40(%rbp) := salva rbx
.globl alocaMem
.type alocaMem, @function
alocaMem:
	pushq %rbp
	movq %rsp, %rbp
	subq $40, %rsp # aloca variaveis locais

	# INICIALIZAÇÃO DAS VARIAVEIS LOCAIS
	movq TOPO_INICIAL_HEAP, %rdx
	movq %rdx, -8(%rbp) # começa a percorrer no começo da heap
	movq TOPO_ATUAL_HEAP, %rax
	movq %rax, -16(%rbp) # -16(%rbp) = firstFit
	movq $0, -24(%rbp) # no inicio, ainda nao tem firstFit
	movq %rdi, -32(%rbp) # numBytes = parametro
	movq %rbx, -40(%rbp) # salva rbx

	# while (nodoAtual != TOPO_ATUAL_HEAP)
	whileAlocaMem:
	movq TOPO_ATUAL_HEAP, %rax
	cmpq %rax, -8(%rbp)
	je fimWhileAlocaMem

	# se firstFit ja foi encontrado, sai do while
	cmpq $1, -24(%rbp)
	je fimWhileAlocaMem
	
	# if (nodoAtual é livre) 
	movq -8(%rbp), %rbx
	movq (%rbx), %rax
	cmpq $1, %rax
	je proximoBlocoAlocaMem

	# if (nodoAtual é livre) e (tam(nodoAtual) >= numBytes)
	movq -8(%rbp), %rbx
	addq $8, %rbx # rbx := endereço do tamanho de notoAtual
	movq (%rbx), %rax # rax := tamanho de nodoAtual
	
	movq -24(%rbp), %rbx
	cmpq $1, %rbx
	je whileAlocaMem

	# se nenhum firstFit foi encontrado até então, altera firstFit para o atual e achouFirstFit = 1
	movq -8(%rbp), %rax
	movq %rax, -16(%rbp)
	movq $1, -24(%rbp)
	jmp proximoBlocoAlocaMem

	proximoBlocoAlocaMem:
	movq -8(%rbp), %rax
	addq $8, %rax
	movq (%rax), %rdi # rdi := tamanho do nodo atual
	addq $16, -8(%rbp) # "pula" as informações gerenciais do bloco atual
	addq %rdi, -8(%rbp) # "pula" os bytes usaveis do bloco atual
	jmp whileAlocaMem # volta para o começo do while

	fimWhileAlocaMem:
	# se firstFit é o topo da heap atual, segue o mesmo fluxo. Se não é, lida com o bloco que vai ser separado
	movq TOPO_ATUAL_HEAP, %rdi
	cmpq -16(%rbp), %rdi
	jne separaFirstFitAlocaMem

	# CASO 1: firstFit é o topo atual da heap
	movq TOPO_ATUAL_HEAP, %r14 # r14 salva topo da heap (que será atualizado)
	addq $16, TOPO_ATUAL_HEAP # abre espaço para as informações gerenciais
	movq -32(%rbp), %rbx # rbx := espaço solicitado
	addq %rbx, TOPO_ATUAL_HEAP # abre espaço solicitado

	# verifica se BRK >= TOPO_ATUAL_HEAP. Se não for, brk precisa ser alterado
	movq TOPO_ATUAL_HEAP, %rax
	movq BRK, %rdi
	cmpq %rax, %rdi
	jge atualizaTopoHeap

	# altera o brk para o primeiro multiplo de 4096 maior que TOPO_ATUAL_HEAP
	movq TOPO_ATUAL_HEAP, %rax
	movq BRK, %rdi
	WhileAcharMultiplo:
	addq $4096, %rdi
	cmpq %rax, %rdi
	jl WhileAcharMultiplo
	movq $12, %rax
	syscall # altera o brk para o valor de %rdi
	movq %rdi, BRK

	atualizaTopoHeap:
	addq $8, %r14 # r14 := endereço que armazena o tamanho do bloco novo
	movq -32(%rbp), %rbx 
	movq %rbx, (%r14) # tamanho do bloco novo := numBytes
	jmp fimAlocaMem

	# CASO 2: firstFit é um bloco que já existe
	separaFirstFitAlocaMem:
	movq -16(%rbp), %rax # rax := firstFit
	movq %rax, %rbx
	addq $8, %rbx # rbx := endereço do tamanho de firstFit
	movq (%rbx), %r10 # r10 := tamanho de firstFit
	movq %r10, %r11 
	subq -32(%rbp), %r11 # r11 := diferença entre tamanho de firstFit e tamanho pedido
	cmpq $16, %r11
	jle fimAlocaMem # se, usando os bytes pedidos, não sobrar espaço para informações gerenciais + bytes usaveis, nao separa o bloco

	# Configura o bloco novo (o segundo)
	addq $8, %rbx # rbx := fim dos bytes de informações gerenciais em firstFit
	addq -32(%rbp), %rbx # rbx := começo do bloco a ser criado
	movq $0, (%rbx) # bloco novo é livre
	subq $16, %r11 # r11 := tamanho do segundo bloco (-16 das informações gerenciais)
	addq $8, %rbx # rbx := endereço da 2a informação gerencial do bloco novo
	movq %r11, (%rbx) # configura tamanho do bloco novo

	# Configura o primeiro bloco (com os bytes pedidos)
	movq %rax, %rbx # rbx := bloco pedido
	addq $8, %rbx # rbx := 2a informação gerencial do bloco pedido
	movq -32(%rbp), %r12 # r12 := numBytes
	movq %r12, (%rbx) # tamanho do bloco pedido = numBytes

	fimAlocaMem:
	movq -16(%rbp), %rax # rax = firstFit (retorno)
	movq $1, (%rax) # 1a informação gerencial do retorno = 1 (bloco usado)
	addq $16, %rax # rax = começo dos bytes usaveis do bloco pedido
	movq -40(%rbp), %rbx # restaura rbx
	addq $40, %rsp # desaloca variaveis locais
	popq %rbp
	ret



.globl imprimeMapa
.type imprimeMapa, @function
imprimeMapa:
	pushq %rbp
	movq %rsp, %rbp
	subq $8, %rsp # aloca variável local nodoAtual

	movq $1, %rax # syscall = write
	movq $1, %rdi # arquivo de saída = stdout

	movq TOPO_INICIAL_HEAP, %r10 # r10 = começo da heap
	movq %r10, -8(%rbp) # nodoAtual = começo da heap

	whileimprimeMapa:
	movq TOPO_ATUAL_HEAP, %r10 # r10 = fim da heap
	cmpq -8(%rbp), %r10 # se nodoAtual = fim da heap, sai do while
	je fimWhileimprimeMapa

	movq $16, %rdx # rdx guarda a quantidade de bytes a ser escrita
	movq $STRING_GERENCIAL, %rsi # string a ser escrita: string gerencial
	syscall

	movq $1, %rdx # rdx guarda a quantidade de bytes a ser escrita
	movq $CHAR_OCUPADO, %rsi 

	movq -8(%rbp), %r10
	movq (%r10), %r11
	cmpq $1, %r11 # se o bloco está ocupado, o char a ser escrito ja esta configurado corretamente
	je fimIfimprimeMapa

	movq $CHAR_LIVRE, %rsi # se o bloco nao esta ocupado, muda para char de bloco livre

	fimIfimprimeMapa:
	addq $8, %r10
	movq (%r10), %r14 # r14 guarda o tamanho do bloco atual
	movq $0, %r12 # usa r12 para iterar sobre o tamanho do bloco

	whileDadosimprimeMapa:
	cmpq %r14, %r12 # se r12 ja imprimiu a quantidade de vezes correta, sai do while
	jge fimWhileDadosimprimeMapa
	movq $1, %rax
	syscall 
	addq $1, %r12
	jmp whileDadosimprimeMapa

	fimWhileDadosimprimeMapa: # volta para o while
	movq -8(%rbp), %r10
	addq $8, %r10
	movq (%r10), %r11

	addq $16, -8(%rbp)
	addq %r11, -8(%rbp)

	jmp whileimprimeMapa

	fimWhileimprimeMapa:
	pushq $'\n' # imprime uma nova linha
	movq $1, %rax
	movq $1, %rdi
	movq %rsp, %rsi
	movq $1, %rdx
	syscall
	addq $8, %rsp

	pushq $'\n' # imprime uma nova linha
	movq $1, %rax # operacao
	movq $1, %rdi # arquivo (stdout)
	movq %rsp, %rsi # o que vai ser escrito
	movq $1, %rdx # quant bytes
	syscall
	addq $8, %rsp
	
	addq $8, %rsp
	popq %rbp
	ret