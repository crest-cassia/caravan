CPP=$(shell (which icpc 2>/dev/null || which FCCpx || which g++-5 || which g++) | tail -n 1)
OPT=-O3 -Wall -DNDEBUG
INCLUDE=
LIBS=

ifeq ($(CPP), FCCpx)
	CPP=FCCpx
	OPT=-Kfast -Xg
endif

libmain.a: *.cpp Makefile
	$(CPP) $(OPT) $(INCLUDE) -c main.cpp $(LIBS) -o main.o
	ar rcs libmain.a main.o

clean:
	rm -f *.out *~ *.bak *.o libmain.a
