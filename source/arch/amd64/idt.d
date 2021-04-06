module arch.amd64.idt;

/* OryxOS Amd64 IDT implementation
 * This implemtation is broken up into 2 sections, the
 * IDT and the exeption handlers, this is done as the
 * exception handlers are mostly copy-past code, with this
 * file being the actual logic
 */

import lib.std.stdio;

import arch.amd64.gdt;

private alias Handler = extern (C) void function();

private enum Gate: ubyte {
	Interrupt = 0b000_01110,
	Trap      = 0b000_00111,
	Task      = 0b000_00101,
}

private enum Present = 0b10000000;

private struct IdtEntry {
	align (1):
	ushort lowBase;
	ushort csSelector;
	ubyte  ist;
	ubyte  attributes;
	ushort midBase;
	uint   highBase;
	uint   reserved;

	this(Handler handler, ubyte ring, Gate gate) {
		size_t address = cast(size_t)(handler);

		this.lowBase    = cast(ushort)(address);
		this.csSelector = KernelCodeSegment;
		this.ist        = 0;
		this.attributes = Present | gate | (ring & 0b00000011);
		this.midBase    = cast(ushort)(address >> 16);
		this.highBase   = cast(uint)(address >> 32);
	}
}

private struct IdtPointer {
	align (1):
	ushort size;
	void* address;
}

private struct InterruptFrame {
	ulong r15;
	ulong r14;
	ulong r13;
	ulong r12;
	ulong r11;
	ulong r10;
	ulong r9;
	ulong r8;
	ulong rdi;
	ulong rsi;
	ulong rbp; 
	ulong rdx;
	ulong rcx;
	ulong rbx;
	ulong rax;

	ulong ident;
	ulong error;

	ulong rip;
	ulong cs;
	ulong eflags;
	ulong rsp; 
	ulong ss;
}

//////////////////////////////
//         Instance         //
//////////////////////////////

private __gshared IdtEntry[256] idtEntries;
private __gshared IdtPointer    idtPointer;

void initIdt() {
	idtPointer = IdtPointer(idtEntries.sizeof - 1, idtEntries.ptr);

	idtEntries[0] = IdtEntry(&divZeroHandler, 0, Gate.Interrupt);
	idtEntries[1] = IdtEntry(&debugHandler, 0, Gate.Interrupt);
	idtEntries[2] = IdtEntry(&dnmiHandler, 0, Gate.Interrupt);


	asm {
		lidt [idtPointer];
	}
}

// Assembly stubs
private extern extern (C) void divZeroHandler();
private extern extern (C) void debugHandler();
private extern extern (C) void nmiHandler();
private extern extern (C) void breakpointHandler();
private extern extern (C) void overflowHandler();

// Names
private __gshared string[] exceptions = [
	"Divide by zero",
	"Debug",
	"Non-maskable interrupt",
	"Breakpoint",
	"Overflow"
];

// Universal exception handler
extern (C) void exceptionHandler(InterruptFrame* frame) {
	panic("%s exception ocured
		Rax: %h\tRbx: %h\tRcx: %h\tRdx: %h", exceptions[frame.ident], frame.rax, frame.rbx, frame.rcx, frame.rdx);
}