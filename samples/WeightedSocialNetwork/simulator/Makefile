UNAME = ${shell uname}
CPP=$(shell (which icpc 2>/dev/null || which FCCpx || which g++-5 || which g++) | tail -n 1)
OPT=-O3 -Wall -DNDEBUG -fopenmp
INCLUDE=
LIBS=

ifeq ($(CPP), FCCpx)
	CPP=FCCpx
	OPT=-Kfast -Xg
	INCLUDE=-I$(HOME)/program/libs/boost_1_54_0
endif

libwsn.a: *.cpp *.hpp Makefile
	$(CPP) $(OPT) $(INCLUDE) -c *.cpp
	ar rcs libwsn.a *.o

clean:
	rm -f *.o libwsn.a
