module arch.amd64.tss;

import au.types;

import io.console;

import lib.collections;

import memory.allocator;

import arch.amd64.gdt;
import arch.amd64.memory;

/* OryxOS Amd64 TSS implementation
 * The TSS is a legacy structure that was peviously
 * used for task switching. Nowaday, the TSS's only
 * purpose is for switching between privilege rings
 */

align private struct Tss {
	align (1):
	uint reserved1;
	ulong[3] priv_stack_tbl;
	ulong reserved2;
	ulong[7] int_stack_tbl;
	ulong reserved3;
	ushort reserved4;
	ushort io_map_addr;
}

//////////////////////////////
//         Instance         //
//////////////////////////////

private __gshared Tss tss;

void init_tss() {
	tss.priv_stack_tbl[0] = cast(ulong) new_arr!(ubyte)(PageSize) + PageSize;
	load_tss(cast(usize) &tss);
}