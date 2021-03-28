import lib.stivale;
import lib.std.stdio;

import io.framebuffer;

extern (C) void main(StivaleInfo* stivale) {
	initFrameBuffer(stivale);
	initConsole();

	/*for (ulong i = 0; i < 256; i++) {
		writeln("%d", i);
	}*/

	writefln("OryxOS Booted");
	stivale.displayBootInfo();


	version (X86_64) {
		import arch.amd64.gdt             : initGdt;
		import arch.amd64.memory.physical : initPmm;
		writefln("\nAmd64 Init:");

		initGdt();
		initPmm(stivale);
	} 

	asm { hlt; }
}