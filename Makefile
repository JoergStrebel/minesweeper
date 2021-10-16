export CXX = g++

CPPFLAGS=-I/usr/local/include -L/usr/local/lib

export CPPFLAGS
export CXXFLAGS = $(CPPFLAGS) -fcx-limited-range -fno-signaling-nans -fno-rounding-math -ffinite-math-only -fno-math-errno -fno-strict-aliasing -O2 -fvisibility=hidden -ggdb -std=c++11 -Wall -Wextra $(CXXUSR)
export CFLAGS = $(CPPFLAGS) $(CXXFLAGS) $(CUSR)
export LDLIBS = -lgecodesearch -lgecodeint -lgecodekernel -lgecodesupport -lgecodedriver -lgecodeminimodel

all: minesweeper

minesweeper.o:	minesweeper.cpp

minesweeper: minesweeper.o
	$(CXX) $(CXXFLAGS) -o $@ $@.o $(LDLIBS)

.PHONY: clean
clean:
	rm -f minesweeper *.o


