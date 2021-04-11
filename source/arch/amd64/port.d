module arch.amd64.port;

/* Amd64 IO Port management
 * Uses C calling convention. casts may be needed
 * to specify size of read/write.
 */

// Ubyte

extern (C) ubyte read(ushort port) {
   asm {
		naked;
		xor EAX, EAX;
		mov DX,  DI;
		in  AL,  DX;
		ret;
	}
}

extern (C) void write(ushort port, ubyte data) {
		asm {
		naked;
		mov DX, DI;
		mov AX, SI;
		out DX, AL;
		ret;
	}
}

// Ushort

extern (C) ubyte read(ushort port) {
   asm {
		naked;
		xor EAX, EAX;
		mov DX,  DI;
		in  AL,  DX;
		ret;
	}
}

extern (C) void write(ushort port, ubyte data) {
		asm {
		naked;
		mov DX, DI;
		mov AX, SI;
		out DX, AL;
		ret;
	}
}

// Uint

extern (C) uint read(ushort port) {
	asm {
		naked;
		xor EAX, EAX;
		mov DX,  DI;
		in  EAX,  DX;
		ret;
	}
}

extern (C) void write(ushort port, uint data) {
	asm {
		naked;
		mov DX, DI;
		mov EAX, ESI;
		out DX, EAX;
		ret;
	}
}