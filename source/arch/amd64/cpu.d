module arch.amd64.cpu;

import au.types;
import io.console;

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