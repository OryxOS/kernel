module arch.amd64;

import lib.std.stdio;
import lib.stivale;

import arch.amd64.memory.physical;
import arch.amd64.memory.virtual;
import arch.amd64.gdt;

void initArch(StivaleInfo* stivale) {
	writefln("\nAmd64 Init:");

	initGdt();
	initPmm(stivale);
	initVmm(stivale);

	writefln("Amd64 Init completed");
}