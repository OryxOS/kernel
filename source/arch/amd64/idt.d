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
import arch.amd64.drivers.legacy.keyboard : kbd_handler;

private alias Handler = extern (C) void function();

private enum Gate: ubyte {
	Interrupt = 0b00001110,
	Trap      = 0b00000111,
	Task      = 0b00000101,
}

private enum Present = 0b10000000;

private struct IdtEntry {
	align (1):
	ushort low_base;
	ushort cs_selector;
	ubyte ist;
	ubyte attributes;
	ushort mid_base;
	uint high_base;
	uint reserved;

	this(Handler handler, ubyte ist, ubyte ring, Gate gate) {
		usize address = cast(usize) handler;

		this.low_base    = cast(ushort) address;
		this.cs_selector = KernelCodeSegment;
		this.ist         = ist;
		this.attributes  = Present | gate | (ring & 0b00000011);
		this.mid_base    = cast(ushort) (address >> 16);
		this.high_base   = cast(uint)   (address >> 32);
	}
}

private struct IdtPointer {
	align (1):
	ushort size;
	void* address;
}

// Useful information for debugging
private align struct InterruptFrame {
	align (1):
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

private __gshared align IdtEntry[256] idt_entries;
private __gshared IdtPointer idt_ptr;

void init_idt() {
	idt_ptr = IdtPointer(idt_entries.sizeof - 1, idt_entries.ptr);

	// Set all exception handlers
	idt_entries[0]  = IdtEntry(&div_zero_handler,      0, 0, Gate.Interrupt);
	idt_entries[1]  = IdtEntry(&debug_handler,         0, 0, Gate.Interrupt);
	idt_entries[2]  = IdtEntry(&nmi_handler,           0, 0, Gate.Interrupt);
	idt_entries[3]  = IdtEntry(&breakpoint_handler,    0, 0, Gate.Interrupt);
	idt_entries[4]  = IdtEntry(&overflow_handler,      0, 0, Gate.Interrupt);
	idt_entries[5]  = IdtEntry(&bound_range_handler,   0, 0, Gate.Interrupt);
	idt_entries[6]  = IdtEntry(&invalid_op_handler,    0, 0, Gate.Interrupt);
	idt_entries[7]  = IdtEntry(&no_device_handler,     0, 0, Gate.Interrupt);
	idt_entries[8]  = IdtEntry(&double_fault_handler,  0, 0, Gate.Interrupt);
	idt_entries[10] = IdtEntry(&invalid_tss_handler,   0, 0, Gate.Interrupt);
	idt_entries[11] = IdtEntry(&seg_absent_handler,    0, 0, Gate.Interrupt);
	idt_entries[12] = IdtEntry(&ss_fault_handler,      0, 0, Gate.Interrupt);
	idt_entries[13] = IdtEntry(&gpf_handler,           0, 0, Gate.Interrupt);
	idt_entries[14] = IdtEntry(&page_fault_handler,    0, 0, Gate.Interrupt);
	idt_entries[16] = IdtEntry(&fpu_fault_handler,     0, 0, Gate.Interrupt);
	idt_entries[17] = IdtEntry(&align_check_handler,   0, 0, Gate.Interrupt);
	idt_entries[18] = IdtEntry(&machine_check_handler, 0, 0, Gate.Interrupt);
	idt_entries[19] = IdtEntry(&simd_fault_handler,    0, 0, Gate.Interrupt);
	idt_entries[20] = IdtEntry(&virt_fault_handler,    0, 0, Gate.Interrupt);
	idt_entries[30] = IdtEntry(&sec_fault_handler,     0, 0, Gate.Interrupt);

	// Legacy devices
	idt_entries[33] = IdtEntry(&kbd_handler, 0, 0, Gate.Interrupt);
	
	asm { lidt [idt_ptr]; }
	log(1, "IDT initialized with %d handlers", idt_entries.length);
}

// Assembly stubs
private extern extern (C) void div_zero_handler();
private extern extern (C) void debug_handler();
private extern extern (C) void nmi_handler();
private extern extern (C) void breakpoint_handler();
private extern extern (C) void overflow_handler();
private extern extern (C) void bound_range_handler();
private extern extern (C) void invalid_op_handler();
private extern extern (C) void no_device_handler();
private extern extern (C) void double_fault_handler();
private extern extern (C) void invalid_tss_handler();
private extern extern (C) void seg_absent_handler();
private extern extern (C) void ss_fault_handler();
private extern extern (C) void gpf_handler();
private extern extern (C) void page_fault_handler();
private extern extern (C) void fpu_fault_handler();
private extern extern (C) void align_check_handler();
private extern extern (C) void machine_check_handler();
private extern extern (C) void simd_fault_handler();
private extern extern (C) void virt_fault_handler();
private extern extern (C) void sec_fault_handler();

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
	"Invalid TSS",
	"Segment not present",
	"Stack segment fault",
	"General protection",
	"Pageing",
	"Invalid",
	"Floating point",
	"Alignment check",
	"Machine check",
	"SIMD",
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
extern (C) void exception_handler(InterruptFrame* frame) {
	put_str("\n[");
	put_chr('!', colours[2]);
	put_str("] ");

	writefln("%s exception occured - Error code: %d \n\tRegisters:\n\t\tRAX: %h\n\t\tRBX: %h\n\t\tRCX: %h\n\t\tRDX: %h\n\t\tRIP: %h\n\t\tRSP: %h\n\t\tRDI: %h\n\t\tRSI: %h",
	         exceptions[frame.ident], frame.error, 
	         frame.rax, frame.rbx, frame.rcx, frame.rdx, frame.rip, 
	         frame.rsp, frame.rdi, frame.rsi);

	asm { hlt; }
}