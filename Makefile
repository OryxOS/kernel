SOURCES=$(wildcard *.cxx) $(wildcard **/*.cxx)
INCLUDES=$(wildcard *.hxx) $(wildcard **/*.hxx)
OBJECTS=$(SOURCES:.cxx=.o)
DEPS=$(SOURCES:.cxx=.d)

CXXFLAGS= \
	-target x86_64-pc-none-elf \
	-ffreestanding \
	-fno-builtin \
    	-nostdlib \
    	-nostdinc \
    	-nostdinc++ \
    	-Wall \
    	-Wpedantic \
    	-Wextra \
    	-Werror \
    	-std=c++20
LDFLAGS= -T Source/Link.ld
 
TARGET=Kernel.elf
FSROOT=../Build/Res/FSRoot

CXX=clang++
LD=ld.lld

#-------------------------------------------------------------------------------

all: $(TARGET)

$(TARGET): $(OBJECTS)
	$(LD) $(LDFLAGS) -o Build/$@ $(OBJECTS)
	cp Build/$@ $(FSROOT)/Kernel.elf

%.o: %.cxx
	$(CXX) $(CXXFLAGS) -c -MD -o $@ $<

-include $(DEPS)

.PHONY: all

