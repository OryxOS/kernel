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
	ushort lowBase;
	ubyte  midBase;
	ubyte  lowFlags;
	ubyte  highFlags;
	ubyte  highBase;

	this(ubyte lowFlags, ubyte highFlags) {
		this.limit     = 0;
		this.lowBase   = 0;
		this.midBase   = 0;
		this.lowFlags  = lowFlags;
		this.highFlags = highFlags;
		this.highBase  = 0;
	}
}

private struct GdtPointer {
	align (1):
	ushort size;
	void* address;
}

// Structure that holds info about a TSS
private struct TssEntry {
	align (1):
	ushort limit;
	ushort lowBase;
	ubyte  midBase;
	ubyte  lowFlags;
	ubyte  highFlags;
	ubyte  highBase;
	uint   upperBase;
	uint   reserved;

	this(ubyte lowFlags, ubyte highFlags) {
		this.limit = 104; // Size of a TSS

		this.lowFlags  = lowFlags;
		this.highFlags = highFlags;

		// Address set later
	}
}

private struct Gdt {
	align (1):
	GdtEntry[5] entries;
	TssEntry    tss;
}

//////////////////////////////
//         Instance         //
//////////////////////////////

// Selectors
enum KernelCodeSegment = 0x08;    
enum KernelDataSegment = 0x10;
enum TssSegment        = 0x28;

private __gshared Gdt gdt;
private __gshared GdtPointer  gdtPointer;

void initGdt() {
	gdt.entries[0] = GdtEntry(0b00000000, 0b00000000); // Null
	gdt.entries[1] = GdtEntry(0b10011010, 0b00100000); // Kernel Code
	gdt.entries[2] = GdtEntry(0b10010010, 0b00000000); // Kernel Data
	gdt.entries[3] = GdtEntry(0b11111010, 0b00100000); // User Code
	gdt.entries[4] = GdtEntry(0b11110010, 0b00000000); // User Data

	gdt.tss = TssEntry(0b10001001, 0); // TSS

	// Set pointer
	gdtPointer = GdtPointer(gdt.sizeof - 1, cast(void*) &gdt);

	// Load the GDT
	asm {
		lgdt [gdtPointer];

		// Long jump to set cs and ss.
		mov RBX, RSP;
		push KernelDataSegment;
		push RBX;
		pushfq;
		push KernelCodeSegment;
		lea RAX, L1; // Putting L1 directly dereferences L1. (According to streaks)
		push RAX;
		iretq;

	L1:;
		mov AX, KernelDataSegment;
		mov DS, AX;
		mov ES, AX;
		mov FS, AX;
		mov GS, AX;
	}

	log(1, "GDT initialized with %d descriptors + 1 TSS descriptor", gdt.entries.length);
}

void loadTss(usize addr) {
	// Address
	gdt.tss.lowBase   = cast(ushort) addr;
	gdt.tss.midBase   = cast(ubyte) (addr >> 16);
	gdt.tss.highBase  = cast(ubyte) (addr >> 24);
	gdt.tss.upperBase = cast(uint) (addr >> 32);

	// Load TSS using `ltr`
	asm {
		push TssSegment;
		ltr [RSP];
		add RSP, 8;
	}
}