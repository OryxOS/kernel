module arch.amd64;

import lib.stivale;
import lib.util.types;
import lib.util.console;

import arch.amd64.gdt       : initGdt;
import arch.amd64.idt       : initIdt;
import arch.amd64.tss       : initTss;
import arch.amd64.pic       : disablePic;
import arch.amd64.apic      : initApic;
import arch.amd64.memory    : initVmm;
import arch.amd64.cpu;

import arch.acpi            : initAcpi;
import arch.acpi.madt       : initMadt;

extern extern (C) void initSyscalls();

void initArch(StivaleInfo* stivale) {
	writefln("\nAmd64 Init:");

	initGdt();
	initIdt();
	initTss();

	initVmm(stivale);

	initAcpi(stivale);
	initMadt();

	disablePic();
	initApic();
	enableInterrupts(true);
	
	initSyscalls();
}