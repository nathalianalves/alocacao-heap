O projeto implementa a alocação de memória na heap em assembly (para a arquitetura AMD64) utilizando três abordagens de alocação: __Best Fit__, __Worst Fit__ e __First Fit__. As funções são implementadas em assembly e ligadas com arquivos .c (main) e .h (cabeçalhos).

#### __Arquivos utilizados no projeto__
* exemplo.c: _main_ usada para testes
* alocador.h: cabeçalho das funções 
* alocadorBestFit.s: implementação das funções utilizando a abordagem best fit para alocação
* alocadorWorstFit.s: implementação das funções utilizando a abordagem worst fit para alocação
* alocadorFirstFit.s: implementação das funções utilizando a abordagem first fit para alocação
* makefile: make que gera arquivos .o e executável (uso explicado na próxima seção)

#### __Uso do makefile__
Com o comando `make` o executável e os arquivos objeto são gerados. 
Definição dos rótulos no arquivo makefile:
* MAIN: nome do arquivo que contém a main (sem a extensão .c)
* ALOCADOR: nome do arquivo que contém a abordagem desejada (sem a extensão .s)
* PROGRAMA: nome do executável gerado

Com o comando `make clean` os arquivos objeto e o executável são apagados.