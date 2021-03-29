module arch.amd64;

import lib.std.stdio;
import lib.stivale;

import arch.amd64.memory.physical;
import arch.amd64.gdt;

void initSys(StivaleInfo* stivale) {
	writefln("\nAmd64 Init:");

	initGdt();
	initPmm(stivale);

	// Try allocating some blocks
	foreach (i; 0..64) {
		PmmResult result = newBlock(1);

		if (result.isOkay) {
			writefln("Block allocated: %h", cast(ulong)(result.unwrapResult()));
		} else {
			writefln("Error: %d", result.unwrapError());
		}
	}
}