module arch.amd64;

import lib.std.stdio;
import lib.stivale;

import arch.amd64.memory;
import arch.amd64.gdt;
import arch.amd64.idt;

void initArch(StivaleInfo* stivale) {
	writefln("\nAmd64 Init:");

	initGdt();
	initIdt();
	initVmm();

	writefln("Amd64 Init completed");
}
