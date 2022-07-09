module arch.amd64.cpu;

// General function relating to Amd64 CPUs

import au.types;

import io.console;

import memory;
import memory.physical;

/* Amd64 IO Port management
 * Uses C calling convention. casts may be needed
 * to specify size of readPort/writePort.
 */

// Ubyte

extern (C) ubyte read_byte(ushort port) {
   asm {
		naked;
		xor EAX, EAX ;
		mov DX,  DI  ;
		in  AL,  DX  ;
		ret;
	}
}

extern (C) void write_byte(ushort port, ubyte data) {
	asm {
		naked;
		mov DX, DI ;
		mov AX, SI ;
		out DX, AL ;
		ret;
	}
}

// Ushort

extern (C) ubyte read_word(ushort port) {
   asm {
		naked;
		xor EAX, EAX ;
		mov DX,  DI  ;
		in  AL,  DX  ;
		ret;
	}
}

extern (C) void write_word(ushort port, ubyte data) {
	asm {
		naked;
		mov DX, DI ;
		mov AX, SI ;
		out DX, AL ;
		ret;
	}
}

// Uint

extern (C) uint read_double(ushort port) {
	asm {
		naked;
		xor EAX, EAX ;
		mov DX,  DI  ;
		in  EAX, DX  ;
		ret;
	}
}

extern (C) void write_double(ushort port, uint data) {
	asm {
		naked;
		mov DX,  DI  ;
		mov EAX, ESI ;
		out DX,  EAX ;
		ret;
	}
}

// Enables or disables interrupts
void enable_ints(bool enable) {
	if (enable)
		asm { sti; }
	else
		asm { cli; }
}