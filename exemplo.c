#include <stdio.h>
#include "alocador.h"

int main (long int argc, char** argv) {
  void *a, *b, *c, *d, *e, *f, *g, *h, *i;

	iniciaAlocador();

	a = (void*) alocaMem(15);
	b = (void*) alocaMem(1);
	c = (void*) alocaMem(10);
	d = (void*) alocaMem(1);
	e = (void*) alocaMem(20);
	f = (void*) alocaMem(1);
	g = (void*) alocaMem(30);
	h = (void*) alocaMem(1);
	i = (void*) alocaMem(25);
	imprimeMapa();
	printf("\n");

	liberaMem(c);
	liberaMem(g);
	liberaMem(i);
	imprimeMapa();
	printf("\n");

	c = alocaMem(10);
	imprimeMapa();
	printf("\n");

	g = alocaMem(5);
	imprimeMapa();
	printf("\n");

	finalizaAlocador();
}
