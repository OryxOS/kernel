module arch.amd64;

import lib.std.stdio;
import lib.stivale;

import arch.amd64.memory;
import arch.amd64.gdt;
import arch.amd64.idt;
import arch.amd64.pic;
import arch.amd64.cpu;

void initArch(StivaleInfo* stivale) {
	writefln("\nAmd64 Init:");

	initGdt();
	initIdt();
	initVmm();
	initPic();
}
