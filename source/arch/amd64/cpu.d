module arch.amd64.cpu;

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