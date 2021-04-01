module arch.amd64.memory.virtual;

import lib.std.stdio;

import arch.amd64.memory;
import arch.amd64.memory.physical;

/* OryxOS Amd64 Virtual Memory Manager
 *
 * Terms:
 *      Pml4 : Top-level paging table    Loaded into Cr4        512 pointers to Pml3 Tables
 *      Pml3 : Level down                                       512 pointers to Pml2 Tables
 *      Pml2 : Level down                                       512 pointers to Pml1 Tables
 *      Pml1 : Level down                                       512 pointers to Pages
 *      Page    : 4 kilobytes of space
 *
 * All tables must be 4kb-aligned. The best way to do this is to allocate a block of
 * physical memory for each Table
 */

private enum Flags: ulong {     // Table:       Description:
	Present         = 1 << 0,   // All          Marks the entry as present in memory
	Writeable       = 1 << 1,   // All          Marks the entry as writeable
	UserAccessable  = 1 << 2,   // All          Marks the entry as accessible from ring-3 code
	WriteThrough    = 1 << 3,   // All          *
	CacheDisable    = 1 << 4,   // All          *
	Accessed        = 1 << 5,   // All          Marks the entry as used by the cpu
	Dirty           = 1 << 6,   // All          Marks the entry as used by software by the cpu
	ExecuteDisable  = 1 << 63,  // All          Marks the entry as non-exectuable - only works if Efer.Nxe is enabled

	Global          = 1 << 8,   // Pml3-1       Marks the entry for global translation - Only works if Cr4.Pge is enabled - huge pages only
	
	Large           = 1 << 7,   // Pml3-2       Marks the entry a pointer to a large page - only works if Cr4.Pse in enabled
	PatLarge        = 1 << 12,  // Pml3-2       *

	PatNormal       = 1 << 7,   // Pml1         *

	/* * = Forms part of PAT ((PAT << 2) | (CD << 1) | WT) - This is
	 *     an index to one of 8 entries into the PAT-MSR,which decides the caching mode
	 * 
	 * Possible cominations:
	 * 1 : WriteCombine :: Stores writes in write buffers and then combines them
	 * 4 : WriteThrough :: Caches reads, not writes
	 * 5 : WriteProtect :: Disables writes
	 * 6 : WriteBack    :: Caches reads and writes
	 * 8 : UnCachable   :: No caching
	 */
}

private align (8) struct Entry {
	ulong entry;

	// Constructs an Entry from a 4kb-aligned address
	this(ulong address, Flags flags) {
		assert(address % PageSize == 0);

		this.entry = ()
	}
}

private alias Table = Entry[512];

private struct AddressSpace {
	Table* root;

	shared this(shared void* rootBlock) {
		// Ensure space given is 4kb-aligned
		assert (cast(ulong)(rootBlock) % PageSize == 0);

		this.root = cast(shared Table*)(rootBlock);
	}
}

//////////////////////////////
//         Instance         //
//////////////////////////////

private shared AddressSpace kernelSpace;

void initVmm() {
	writefln("\tIntializing Vmm:");

	// Alloc enough space for root table
	PmmResult rootBlock = newBlock(1);

	if (rootBlock.isOkay) {
		kernelSpace = shared AddressSpace(cast(shared void*)(rootBlock.unwrapResult));
	} else {
		panic(2, "Cannot allocate space for root page table");
	}
}