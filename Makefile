.PHONY: clean

KERNEL    := kernel.elf

SOURCEDIR := source
BUILDDIR  := build
LIBDIR    := ../libraries

# Actual libraries the project uses (used for linking)
LIBS := ../libraries/au

# Software
DC   = ldc2
AS   = nasm
LD   = ld.lld

# Flags
DFLAGS  := -mtriple=amd64-unknown-elf -relocation-model=static \
           -code-model=kernel -mattr=-sse,-sse2,-sse3,-ssse3 -disable-red-zone \
           -betterC -op -O
LDFLAGS := --oformat elf_amd64 --nostdlib
ASFLAGS := -felf64

# Source to compile.
LIBDSOURCE := $(shell find $(LIBS) -type f -name '*.d')
ASMSOURCE  := $(shell find $(SOURCEDIR) -type f -name '*.asm')
DSOURCE    := $(shell find $(SOURCEDIR) -type f -name '*.d')
OBJ        := $(DSOURCE:.d=.o) $(ASMSOURCE:.asm=.o) $(LIBDSOURCE:.d=.o)

all: $(KERNEL)

$(KERNEL): $(OBJ)
	@$(LD) $(LDFLAGS) $(OBJ) -T $(BUILDDIR)/link.ld -o $@

%.o: %.d
	@$(DC) $(DFLAGS) -I=$(SOURCEDIR) -I=$(LIBDIR) -c $< -of=$@

%.o: %.asm
	@$(AS) $(ASFLAGS) -I$(SOURCEDIR) $< -o $@

clean:
	rm -rf $(OBJ) $(KERNEL)