module arch.amd64;

import lib.std.stdio;
import lib.stivale;

import arch.amd64.memory    : initVmm;
import arch.amd64.gdt       : initGdt;
import arch.amd64.idt       : initIdt;
import arch.amd64.pic       : initPic;

import arch.acpi            : initAcpi; 

void initArch(StivaleInfo* stivale) {
	writefln("\nAmd64 Init:");

	// Low level structures
	initGdt();
	initIdt();
	initPic();
	initVmm(stivale);

	//initAcpi(stivale);
}