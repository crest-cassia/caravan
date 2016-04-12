CPP=$(shell (which icpc 2>/dev/null || which g++-4.9 || which g++) | tail -n 1)
OPT=-O3 -Wall -DNDEBUG
INCLUDE=
LIBS=

libising2d.a: *.cpp *.hpp Makefile
	$(CPP) $(OPT) $(INCLUDE) -c main.cpp $(LIBS) -o main.o
	ar rcs libising2d.a main.o

clean:
	rm -f *.out *~ *.bak *.o libising2d.a
