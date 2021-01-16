SOURCES=$(wildcard *.cxx) $(wildcard **/*.cxx)
INCLUDES=$(wildcard *.hxx) $(wildcard **/*.hxx)
OBJECTS=$(SOURCES:.cxx=.o)
DEPS=$(SOURCES:.cxx=.d)

CXXFLAGS=-std=gnu++11 -Wall -Wextra -Wpedantic -Wshadow -g -O2
LDFLAGS=

TARGET=Kernel.elf
CXX=clang++

#-------------------------------------------------------------------------------

all: $(TARGET)


clean:
	-rm $(DEPS) $(OBJECTS)

spotless: clean
	-rm $(TARGET)

format:
	clang-format -i $(SOURCES) $(INCLUDES)

install:
	echo "Installing is not supported"

run:
	./CxxTest

$(TARGET): $(OBJECTS)
	$(CXX) $(LDFLAGS) -o $@ $(OBJECTS)

%.o: %.cxx
	$(CXX) $(CXXFLAGS) -c -MD -o $@ $<

-include $(DEPS)

.PHONY: all clean format spotless

