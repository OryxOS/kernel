module arch.amd64.cpu;

import lib.util.types;
import lib.util.console;

import common.memory;
import arch.amd64.memory;
import common.memory.physical;

// General function relating to Amd64 CPUs


/* Amd64 IO Port management
 * Uses C calling convention. casts may be needed
 * to specify size of readPort/writePort.
 */

// Ubyte

extern (C) ubyte readByte(ushort port) {
   asm {
		naked;
		xor EAX, EAX ;
		mov DX,  DI  ;
		in  AL,  DX  ;
		ret;
	}
}

extern (C) void writeByte(ushort port, ubyte data) {
	asm {
		naked;
		mov DX, DI   ;
		mov AX, SI   ;
		out DX, AL   ;
		ret;
	}
}

// Ushort

extern (C) ubyte readWord(ushort port) {
   asm {
		naked;
		xor EAX, EAX ;
		mov DX,  DI  ;
		in  AL,  DX  ;
		ret;
	}
}

extern (C) void writeWord(ushort port, ubyte data) {
	asm {
		naked;
		mov DX, DI   ;
		mov AX, SI   ;
		out DX, AL   ;
		ret;
	}
}

// Uint

extern (C) uint readDouble(ushort port) {
	asm {
		naked;
		xor EAX, EAX ;
		mov DX,  DI  ;
		in  EAX, DX  ;
		ret;
	}
}

extern (C) void writeDouble(ushort port, uint data) {
	asm {
		naked;
		mov DX,  DI  ;
		mov EAX, ESI ;
		out DX,  EAX ;
		ret;
	}
}

// Enables or disables interrupts
void enableInterrupts(bool enable) {
	if (enable)
		asm { sti; }
	else
		asm { cli; }
}

/* Context management
 * A Context is the environment in which a CPU operates
 * It consists of registers, the stack and page tables.
 * Contexts are the most basic taking structure
 */

// Amd64 registers
struct Registers {
    // General registers
    ulong rax;
    ulong rbx;
    ulong rcx;
    ulong rdx;

    // Additional registers
    ulong r8;
    ulong r9;
    ulong r10;
    ulong r11;
    ulong r12;
    ulong r15;

    // Other
    ulong rip;
    ulong rsi;
    ulong rdi;
    ulong rbp;

    ulong rflags;
}

extern extern (C) void jumpUserSpace(VirtAddress start, VirtAddress stack);

struct Context {
	Registers    registers;
	AddressSpace addressSpace;
	VirtAddress  stack;
	VirtAddress  textStart;

	// Creates a new userspace context
	this(usize textStart, usize textSize) {
		this.textStart = cast(void*) textStart;

		this.addressSpace = AddressSpace(newBlock()
		                                .unwrapResult("Not enough space for process's PML Tables"));

		usize stackBottom = cast(usize) newBlock().unwrapResult("Not enough space for stack");

		this.stack = cast(void*) (stackBottom + PageSize);

		// Map kernel and higher half
		auto procTables = cast(ulong[512]*) this.addressSpace.pml4;
		auto kernTables = cast(ulong[512]*) kernelSpace.pml4;

		(*procTables)[256] = (*kernTables)[256]; // Higher half
		(*procTables)[511] = (*kernTables)[511]; // Kernel

		// Map process's text section
		this.addressSpace.mapPage(cast(VirtAddress) textStart, cast(PhysAddress) textStart,
		                          EntryFlags.Present | EntryFlags. Writeable | EntryFlags.UserAccessable);

		// Map process's stack
		this.addressSpace.mapPage(cast(VirtAddress) stackBottom, cast(PhysAddress) stackBottom,
		                          EntryFlags.Present | EntryFlags. Writeable | EntryFlags.UserAccessable);
	}

	void start() {
		this.addressSpace.setActive();
		jumpUserSpace(this.textStart, this.stack);
	}
}
