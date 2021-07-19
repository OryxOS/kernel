module arch.amd64.tss;

import lib.util.heap;
import lib.util.types;
import lib.util.console;

import arch.amd64.gdt;

/* OryxOS Amd64 TSS implementation
 * The TSS is a legacy structure that was peviously
 * used for task switching. Nowaday, the TSS's only
 * purpose is for switching between privilege rings
 */

align (16) private struct Tss {
	align (1):
	uint     reserved1;
	ulong[3] privStackTable;
	ulong    reserved2;
	ulong[7] intStackTable;
	ulong    reserved3;
	ushort   reserved4;
	ushort   ioMapAddr;
}

//////////////////////////////
//         Instance         //
//////////////////////////////

private __gshared Tss tss;

void initTss() {
	tss.privStackTable[0] = cast(ulong) newArr!(ubyte)(4096);
	loadTss(cast(usize) &tss);
}