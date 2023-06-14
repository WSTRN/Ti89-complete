CC=gcc
CXX=g++
CFLAGS=-O2 -fomit-frame-pointer -Wall
RM=rm -rf

all: makeprgm

clean:
	$(RM) makeprgm *~

distclean: clean

makeprgm: makeprgm.cc  object.cc  prog.cc object.h  prog.h  progstub.h
	$(CXX) $(CFLAGS) makeprgm.cc  object.cc  prog.cc -o makeprgm
