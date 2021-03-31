import lib.stivale;
import lib.std.stdio;
import lib.std.result;

import io.framebuffer;

version (X86_64) import arch.amd64;

extern (C) void main(StivaleInfo* stivale) {
	initFrameBuffer(stivale);
	initConsole();

	writefln("OryxOS Booted");
	stivale.displayBootInfo();

	initArch(stivale);

	asm { hlt; }
}
