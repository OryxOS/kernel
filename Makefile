.PHONY: clean

KERNEL    := oryx.kernel

SOURCEDIR := source
BUILDDIR  := build


# Software
DC   = ldc2
AS   = nasm
LD   = ld.lld

#Flags
DFLAGS := -mtriple=amd64-unknown-elf -relocation-model=static \
	-code-model=kernel -mattr=-sse,-sse2,-sse3,-ssse3 -disable-red-zone     \
	-betterC -op -O -release

LDFLAGS   := --oformat elf_amd64 --nostdlib

ASFLAGS   := $(ASFLAGS) -felf64

# Source to compile.
DSOURCE   := $(shell find $(SOURCEDIR) -type f -name '*.d')
ASMSOURCE := $(shell find $(SOURCEDIR) -type f -name '*.asm')
OBJ       := $(DSOURCE:.d=.o) $(ASMSOURCE:.asm=.o)

all: $(KERNEL)

$(KERNEL): $(OBJ)
	@$(LD) $(LDFLAGS) $(OBJ) -T $(BUILDDIR)/link.ld -o $@

%.o: %.d
	@$(DC) $(DFLAGS) -I=$(SOURCEDIR) -c $< -of=$@

%.o: %.asm
	@$(AS) $(ASFLAGS) -I$(SOURCEDIR) $< -o $@

clean:
	rm -rf $(OBJ) $(KERNEL)