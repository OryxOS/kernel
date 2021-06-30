import lib.stivale;
import lib.std.stdio;

import shell                   : shellMain;
import io.framebuffer          : initFrameBuffer;
import common.memory.physical  : initPmm;

version (X86_64) import arch.amd64;

extern (C) void main(StivaleInfo* stivale) {
	initFrameBuffer(stivale);
	initConsole();

	writefln("OryxOS Booted!");
	stivale.displayBootInfo();

	initPmm(stivale);
	initArch(stivale);

	//shellMain();

	while (1) {}
}