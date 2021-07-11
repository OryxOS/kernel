module arch.amd64;

import lib.stivale;
import lib.util.console;

import arch.amd64.gdt       : initGdt;
import arch.amd64.idt       : initIdt;
import arch.amd64.pic       : initPic;
import arch.amd64.memory    : initVmm;


import arch.acpi            : initAcpi;
import arch.acpi.madt       : initMadt; 

void initArch(StivaleInfo* stivale) {
	writefln("\nAmd64 Init:");

	// Low level structures
	initGdt();
	initIdt();
	initPic();
	initVmm(stivale);

	initAcpi(stivale);
	initMadt();
}