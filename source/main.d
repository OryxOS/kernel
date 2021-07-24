import lib.stivale;
import lib.util.console;

import shell                   : shellMain;
import io.framebuffer          : initFrameBuffer;
import common.memory.physical  : initPmm;
import common.memory.alloc     : initAlloc;
import common.scheduler        : initScheduler;

version (X86_64) import arch.amd64;
version (X86_64) import arch.amd64.drivers.legacy.keyboard;

extern (C) void main(StivaleInfo* stivale) {
	initFrameBuffer(stivale);
	initConsole();

	writefln("OryxOS Booted!");
	stivale.displayBootInfo();

	initPmm(stivale);
	initAlloc();

	initArch(stivale);

	initScheduler(stivale);
	
	while (1) {}
}