SOURCES=$(shell find Source/ -type f -name '*.cxx')
INCLUDES=$(shell find Source/ -type f -name '*.hxx')
OBJECTS=$(SOURCES:.cxx=.o)
DEPS=$(SOURCES:.cxx=.d)

LIBDIR=-ISource/

CXXFLAGS= \
	$(LIBDIR) \
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
        -Wold-style-cast \
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

