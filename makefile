FLAGS = -g -Wall -no-pie
MAIN = avalia
ALOCADOR = alocadorFirstFit
PROGRAMA = alocador

all: $(PROGRAMA)

$(PROGRAMA): $(MAIN).o $(ALOCADOR).o
	gcc $(FLAGS) -o $(PROGRAMA) $(MAIN).o $(ALOCADOR).o

$(AVALIA).o: .c
	gcc -c $(FLAGS) $(MAIN).c -o $(MAIN).o

$(ALOCADOR).o: $(ALOCADOR).s alocador.h
	as $(ALOCADOR).s -o $(ALOCADOR).o

clean:
	rm -f *.o $(PROGRAMA)