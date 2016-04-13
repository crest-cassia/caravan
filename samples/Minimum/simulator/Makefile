CPP=$(shell (which icpc 2>/dev/null || which g++-4.9 || which g++) | tail -n 1)
OPT=-O3 -Wall -DNDEBUG
INCLUDE=
LIBS=

libmain.a: *.cpp Makefile
	$(CPP) $(OPT) $(INCLUDE) -c main.cpp $(LIBS) -o main.o
	ar rcs libmain.a main.o

clean:
	rm -f *.out *~ *.bak *.o libmain.a
