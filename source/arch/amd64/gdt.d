module arch.amd64.gdt;

/* OryxOS Amd64 GDT implementation
 * The GDT isn't very important im the Amd64 architecture and is mostly
 * a set-once structure. becuase of this, this GDT implementation is 
 * very simplistic and unflexible.
 */

import au.types;

import io.console;

private struct GdtEntry {
	align (1):
	ushort limit;
	ushort low_base;
	ubyte mid_base;
	ubyte low_flags;
	ubyte high_flags;
	ubyte high_base;

	this(ubyte low_flags, ubyte high_flags) {
		this.limit      = 0;
		this.low_base   = 0;
		this.mid_base   = 0;
		this.low_flags  = low_flags;
		this.high_flags = high_flags;
		this.high_base  = 0;
	}
}

private struct TssEntry {
	align (1):
	ushort limit;
	ushort low_base;
	ubyte mid_base;
	ubyte low_flags;
	ubyte high_flags;
	ubyte high_base;
	uint upper_base;
	uint reserved;

	this(ubyte low_flags, ubyte high_flags) {
		this.limit = 104;

		this.low_flags  = low_flags;
		this.high_flags = high_flags;

		// Address set later
	}
}

private struct GdtPointer {
	align (1):
	ushort size;
	void* address;
}

private struct Gdt {
	align (1):
	GdtEntry[6] entries;
	TssEntry tss;
}

//////////////////////////////
//         Instance         //
//////////////////////////////

// Selectors
enum KernelCodeSegment = 0x08;    
enum KernelDataSegment = 0x10;
enum UserDataSegment   = 0x20;
enum UserCodeSegment   = 0x28;
enum TssSegment        = 0x30;

private __gshared Gdt gdt;
private __gshared GdtPointer  gdt_ptr;

void init_gdt() {
	gdt.entries[0] = GdtEntry(0b00000000, 0b00000000); // Null
	gdt.entries[1] = GdtEntry(0b10011010, 0b00100000); // Kernel Code
	gdt.entries[2] = GdtEntry(0b10010010, 0b00000000); // Kernel Data
	gdt.entries[3] = GdtEntry(0b00000000, 0b00000000); // Null (Comp mode code segment)
	gdt.entries[4] = GdtEntry(0b11110010, 0b00000000); // User Data
	gdt.entries[5] = GdtEntry(0b11111010, 0b00100000); // User Code

	gdt.tss = TssEntry(0b10001001, 0); // TSS

	// Set pointer
	gdt_ptr = GdtPointer(gdt.sizeof - 1, cast(void*) &gdt);

	// Load the GDT
	asm {
		lgdt [gdt_ptr];

		// Long jump to set cs and ss.
		mov RBX, RSP           ;
		push KernelDataSegment ;
		push RBX               ;
		pushfq                 ;
		push KernelCodeSegment ;
		// Putting L1 directly dereferences L1.
		lea RAX, L1            ;
		push RAX               ;
		iretq                  ;

	L1:;
		mov AX, KernelDataSegment ;
		mov DS, AX                ;
		mov ES, AX                ;
		mov FS, AX                ;
		mov GS, AX                ;
		mov SS, AX                ;
	}

	log(1, "GDT initialized with %d descriptors + 1 TSS descriptor", gdt.entries.length);
}

void load_tss(usize addr) {
	// Address
	gdt.tss.low_base   = cast(ushort) addr;
	gdt.tss.mid_base   = cast(ubyte) (addr >> 16);
	gdt.tss.high_base  = cast(ubyte) (addr >> 24);
	gdt.tss.upper_base = cast(uint) (addr >> 32);

	// Load TSS using `ltr`
	asm {
		push TssSegment;
		ltr [RSP];
		add RSP, 8;
	}
}