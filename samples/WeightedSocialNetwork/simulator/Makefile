UNAME = ${shell uname}
CPP=$(notdir $(shell (which FCCpx 2>/dev/null || which g++-5 || which g++) | tail -n 1) )
OPT=-O3 -Wall -DNDEBUG -fopenmp
INCLUDE=
LIBS=

ifeq ($(CPP),FCCpx)
	OPT=-Kfast -Xg
	INCLUDE=-I$(BOOST_PATH)
endif

libwsn.a: *.cpp *.hpp Makefile
	$(CPP) $(OPT) $(INCLUDE) -c *.cpp
	ar rcs libwsn.a *.o

clean:
	rm -f *.o libwsn.a
