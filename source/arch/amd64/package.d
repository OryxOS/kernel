module arch.amd64;

import lib.std.stdio;
import lib.stivale;

import arch.amd64.memory.physical;
import arch.amd64.gdt;


import common.memory;
import arch.amd64.memory;


void initSys(StivaleInfo* stivale) {
	writefln("\nAmd64 Init:");

	initGdt();
	initPmm(stivale);

	// Print the Memory map
	RegionInfo info = RegionInfo(cast(MemMapTag*)(stivale.getTag(MemMapID)));

	writefln("\nRegions:");
	foreach(i; 0..info.count) {
		writefln("Region: [ Base: %h\t\tSize: %h\t\tType: %d\t\t]", info.regions[i].base, info.regions[i].length, cast(uint)(info.regions[i].type));
	}

	/*// Try allocating some blocks
	foreach (i; 0..10) {
		PmmResult result = newBlock(1);

		if (result.isOkay) {
			writefln("Block allocated: %h", cast(ulong)(result.unwrapResult()));
		} else {
			writefln("Error: %d", result.unwrapError());
		}
	} */
}