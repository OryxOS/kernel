module arch.amd64.idt;

/* OryxOS Amd64 IDT implementation
 * This implemtation is broken up into 2 sections, the
 * IDT and the exeption handlers, this is done as the
 * exception handlers are mostly copy-past code, with this
 * file being the actual logic
 */

import au.types;
import io.console;

import arch.amd64.gdt                     : KernelCodeSegment;
import arch.amd64.drivers.legacy.keyboard : keyboardHandler;

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
		usize address = cast(usize) handler;

		this.lowBase    = cast(ushort) address;
		this.csSelector = KernelCodeSegment;
		this.ist        = 0;
		this.attributes = Present | gate | (ring & 0b00000011);
		this.midBase    = cast(ushort) (address >> 16);
		this.highBase   = cast(uint)   (address >> 32);
	}
}

private struct IdtPointer {
	align (1):
	ushort size;
	void* address;
}

// Useful information for debugging
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

	// Set all exception handlers
	idtEntries[0]  = IdtEntry(&divZeroHandler,       0, Gate.Interrupt);
	idtEntries[1]  = IdtEntry(&debugHandler,         0, Gate.Interrupt);
	idtEntries[2]  = IdtEntry(&nmiHandler,           0, Gate.Interrupt);
	idtEntries[3]  = IdtEntry(&breakpointHandler,    0, Gate.Interrupt);
	idtEntries[4]  = IdtEntry(&overflowHandler,      0, Gate.Interrupt);
	idtEntries[5]  = IdtEntry(&boundRangeHandler,    0, Gate.Interrupt);
	idtEntries[6]  = IdtEntry(&invOpcodeHandler,     0, Gate.Interrupt);
	idtEntries[7]  = IdtEntry(&noDeviceHandler,      0, Gate.Interrupt);
	idtEntries[8]  = IdtEntry(&doubleFaultHandler,   0, Gate.Interrupt);
	idtEntries[10] = IdtEntry(&invTssHandler,        0, Gate.Interrupt);
	idtEntries[11] = IdtEntry(&segNotPresentHandler, 0, Gate.Interrupt);
	idtEntries[12] = IdtEntry(&ssFaultHandler,       0, Gate.Interrupt);
	idtEntries[13] = IdtEntry(&gpfHandler,           0, Gate.Interrupt);
	idtEntries[14] = IdtEntry(&pageFaultHandler,     0, Gate.Interrupt);
	idtEntries[16] = IdtEntry(&fpuFaultHandler,      0, Gate.Interrupt);
	idtEntries[17] = IdtEntry(&alignCheckHandler,    0, Gate.Interrupt);
	idtEntries[18] = IdtEntry(&machineCheckHandler,  0, Gate.Interrupt);
	idtEntries[19] = IdtEntry(&simdFaultHandler,     0, Gate.Interrupt);
	idtEntries[20] = IdtEntry(&virtFaultHandler,     0, Gate.Interrupt);
	idtEntries[30] = IdtEntry(&secFaultHandler,      0, Gate.Interrupt);

	// Legacy devices
	idtEntries[33] = IdtEntry(&keyboardHandler,      0, Gate.Interrupt);
	
	asm { lidt [idtPointer]; }
	log(1, "IDT initialized with %d handlers", idtEntries.length);
}

// Assembly stubs
private extern extern (C) void divZeroHandler();
private extern extern (C) void debugHandler();
private extern extern (C) void nmiHandler();
private extern extern (C) void breakpointHandler();
private extern extern (C) void overflowHandler();
private extern extern (C) void boundRangeHandler();
private extern extern (C) void invOpcodeHandler();
private extern extern (C) void noDeviceHandler();
private extern extern (C) void doubleFaultHandler();
private extern extern (C) void invTssHandler();
private extern extern (C) void segNotPresentHandler();
private extern extern (C) void ssFaultHandler();
private extern extern (C) void gpfHandler();
private extern extern (C) void pageFaultHandler();
private extern extern (C) void fpuFaultHandler();
private extern extern (C) void alignCheckHandler();
private extern extern (C) void machineCheckHandler();
private extern extern (C) void simdFaultHandler();
private extern extern (C) void virtFaultHandler();
private extern extern (C) void secFaultHandler();

// Names
private __gshared string[] exceptions = [
	"Divide by zero",
	"Debug",
	"Non-maskable interrupt",
	"Breakpoint",
	"Overflow",
	"Out of bounds",
	"Invalid Opcode",
	"Device not dound",
	"Double fault",
	"Invalid",
	"Invalid Tss",
	"Segment not present",
	"Stack segment dault",
	"General protection",
	"Pageing",
	"Invalid",
	"Floating point",
	"Alignment check",
	"Machine check",
	"Simd",
	"Virtualization",
	"Invalid",
	"Invalid",
	"Invalid",
	"Invalid",
	"Invalid",
	"Invalid",
	"Invalid",
	"Invalid",
	"Invalid",
	"Invalid",
	"Security"
];

// Universal exception handler
extern (C) void exceptionHandler(InterruptFrame* frame) {
	writefln("%s exception occured - Error code: %d
		RAX: %h\tRBX: %h\tRCX: %h\tRDX: %h
		RIP: %h\tRSP: %h\tRDI: %h\tRSI: %h", exceptions[frame.ident], frame.error, 
		frame.rax, frame.rbx, frame.rcx, frame.rdx, frame.rip, 
		frame.rsp, frame.rdi, frame.rsi);

	asm { hlt; }
}