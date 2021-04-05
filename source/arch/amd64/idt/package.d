module arch.amd64.idt;

/* OryxOS Amd64 IDT implementation
 * This implemtation is broken up into 2 sections, the
 * IDT and the exeption handlers, this is done as the
 * excpetion handlers are mostly copy-past code, with this
 * file being the actual logic
 */

import lib.std.stdio;

import arch.amd64.gdt;

private alias Handler = extern (C) void function();

private struct IdtEntry {
	align (1):
	ushort lowBase;
	ushort csSelector;
	ubyte  ist;
	ubyte  attributes;
	ushort midBase;
	uint   highBase;
	uint   reserved;

	this(Handler handler) {
		this.lowBase    = cast(ushort)(handler);
		this.csSelector = kernelCodeSegment;
		this.ist        = 0;
		
	}
}

private struct IdtPointer {
	align (1):
	ushort size;
	void* address;
}

//////////////////////////////
//         Instance         //
//////////////////////////////

private __gshared IdtEntry[256] idtEntries;
private __gshared IdtPointer    idtPointer;