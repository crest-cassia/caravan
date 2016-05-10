CPP=$(shell (which FCCpx 2>/dev/null || which g++-5 || which g++) | tail -n 1)
OPT=-O3 -Wall -DNDEBUG
INCLUDE=
LIBS=

ifeq ($(CPP), FCCpx)
	CPP=FCCpx
	OPT=-Kfast -Xg
	INCLUDE=-I$(HOME)/program/libs/boost_1_54_0
endif

libising2d.a: *.cpp *.hpp Makefile
	$(CPP) $(OPT) $(INCLUDE) -c main.cpp $(LIBS) -o main.o
	ar rcs libising2d.a main.o

clean:
	rm -f *.out *~ *.bak *.o libising2d.a
