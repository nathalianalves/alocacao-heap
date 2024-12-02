FLAGS = -g -Wall -no-pie
PROGRAMA = alocador

all: $(PROGRAMA)

$(PROGRAMA): exemplo.o alocador.o
	gcc $(FLAGS) -o $(PROGRAMA) exemplo.o alocador.o

exemplo.o: exemplo.c
	gcc -c $(FLAGS) exemplo.c -o exemplo.o

alocador.o: alocador.s alocador.h
	as alocador.s -o alocador.o

clean:
	rm -f *.o $(PROGRAMA)