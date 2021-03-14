module arch.amd64.memory.gdt;

/* OryxOS Amd64 GDT implementation
 * The GDT isn't very import on the Amd64 architecture and is mostly a set-once structure.
 * becuase of this, this GDT implementation is very simplistic and unflexible.
 */

import io.console;

private struct GdtEntry {
	align(1):
	ushort limit;
	ushort lowBase;
	ubyte  midBase;
	ubyte  lowFlags;
	ubyte  highFlags;
	ubyte  highbase;

	this(ubyte lowFlags, ubyte highFlags) {
		this.limit     = 0;
		this.lowBase   = 0;
		this.midBase   = 0;
		this.lowFlags  = lowFlags;
		this.highFlags = highFlags;
		this.highbase  = 0;
	}
}

private struct GdtPointer {
	align(1):
	ushort size;
	void* address;
}

//////////////////////////////
//         Instance         //
//////////////////////////////

// Selectors
immutable CODE_SEGMENT = 0x08;    
immutable DATA_SEGMENT = 0x10;

private __gshared GdtEntry[3] gdtEntries;
private __gshared GdtPointer  gdtPointer;

void initGdt() {
	gdtEntries[0] = GdtEntry(0b00000000, 0b00000000); // Null
	gdtEntries[1] = GdtEntry(0b10011010, 0b00100000); // Kernel Code
	gdtEntries[2] = GdtEntry(0b10010010, 0b00000000); // Kernel Data

	// Set pointer
	gdtPointer = GdtPointer(gdtEntries.sizeof - 1, cast(void*)&gdtEntries);

	// Load the GDT
	asm {
		lgdt [gdtPointer];

		// Long jump to set cs and ss.
		mov RBX, RSP;
		push DATA_SEGMENT;
		push RBX;
		pushfq;
		push CODE_SEGMENT;
		lea RAX, L1; // Putting L1 directly dereferences L1. (According to streak)
		push RAX;
		iretq;

	L1:;
		mov AX, DATA_SEGMENT;
		mov DS, AX;
		mov ES, AX;
		mov FS, AX;
		mov GS, AX;
	}

	// Log the success:
	writeln("[+] GDT Initliazed");
}