module arch.amd64.memory.virtual;

import lib.stivale;
import lib.std.stdio;
import lib.std.result;

import common.memory;
import arch.amd64.memory;
import arch.amd64.memory.physical;

/* OryxOS Amd64 Virtual Memory Manager
 *
 * Terms:
 *      Pml4 : Top-level paging table    Loaded into Cr4        512 pointers to Pml3 Tables
 *      Pml3 : Level down                                       512 pointers to Pml2 Tables
 *      Pml2 : Level down                                       512 pointers to Pml1 Tables
 *      Pml1 : Level down                                       512 pointers to Pages
 *      Page : 4 kilobytes of space
 *
 * All tables must be 4kb-aligned. The best way to do this is to allocate a block of
 * physical memory for each Table. Currently this Vmm only supports 4 level paging,
 * however this will change in the future
 */

private enum Flags {         // Table:       Description:
	Present         = 1UL << 0,     // All          Marks the entry as present in memory
	Writeable       = 1UL << 1,     // All          Marks the entry as writeable
	UserAccessable  = 1UL << 2,     // All          Marks the entry as accessible from ring-3 code
	WriteThrough    = 1UL << 3,     // All          *
	CacheDisable    = 1UL << 4,     // All          *
	Accessed        = 1UL << 5,     // All          Marks the entry as used by the cpu
	Dirty           = 1UL << 6,     // All          Marks the entry as used by software by the cpu
	ExecuteDisable  = 1UL << 63,    // All          Marks the entry as non-exectuable - only works if Efer.Nxe is enabled

	Global          = 1UL << 8,     // Pml3-1       Marks the entry for global translation - Only works if Cr4.Pge is enabled - huge pages only
	
	Large           = 1UL << 7,     // Pml3-2       Marks the entry a pointer to a large page - only works if Cr4.Pse in enabled
	PatLarge        = 1UL << 12,    // Pml3-2       *

	PatNormal       = 1UL << 7,     // Pml1         *

	/* * = Forms part of PAT ((PAT << 2) | (CD << 1) | WT) - This is
	 *     an index to one of 8 entries into the PAT-MSR, which decides the caching mode
	 * 
	 * Possible cominations:
	 * 1 : WriteCombine :: Stores writes in write buffers and then combines them
	 * 4 : WriteThrough :: Caches reads, not writes
	 * 5 : WriteProtect :: Disables writes
	 * 6 : WriteBack    :: Caches reads and writes
	 * 8 : UnCachable   :: No caching
	 */
}

private alias Entry = ulong;

private enum VmmResult {
	Good,
	NotEnoughSpaceForTables,
}

struct AddressSpace {
	private Entry* pml4;

	this(PhysAddress pml4Block) {
		assert (cast(ulong)(pml4Block) % PageSize == 0);

		this.pml4 = cast(Entry*)(pml4Block + PhysOffset);
	}

	void setActive() {
		Entry* root = this.pml4 - PhysOffset;
		asm { 
			mov RAX, root;
			mov CR3, RAX; 
		}
	}

	VmmResult mapPage(VirtAddress virtual, PhysAddress physical, Flags flags) {
		assert(cast(size_t)(physical) % PageSize == 0);
		assert(cast(size_t)(virtual)  % PageSize == 0);

		// Find or create the required pml table
		Entry* pml1Entry = getPml1Entry(virtual, flags, true);

		writefln("Entry: %h", cast(ulong)(pml1Entry));

		// Not enough memory to create tables
		if (pml1Entry == null)
			return VmmResult.NotEnoughSpaceForTables;

		*pml1Entry = cast(ulong)(physical) | flags;

		return VmmResult.Good;
	}

	private Entry* getPml1Entry(VirtAddress virtual, Flags flags, bool create) {
		// Calculate the Indices into each pml table
		immutable ulong pml4Entry = (cast(ulong)(virtual) & 0x1FFUL << 39) >> 39;
		immutable ulong pml3Entry = (cast(ulong)(virtual) & 0x1FFUL << 30) >> 30;
		immutable ulong pml2Entry = (cast(ulong)(virtual) & 0x1FFUL << 21) >> 21;
		immutable ulong pml1Entry = (cast(ulong)(virtual) & 0x1FFUL << 12) >> 12;

		Entry* pml3 = getNextLevel(this.pml4, pml4Entry, flags, create);
		Entry* pml2 = getNextLevel(pml3, pml3Entry, flags, create);
		Entry* pml1 = getNextLevel(pml2, pml2Entry, flags, create);

		// Check we didn't run out of memory
		if (pml3 == null || pml2 == null || pml1 == null)
			return null;

		// Return the good result
		return cast(Entry*)(&pml1[pml1Entry]);
	}
	
	// Finds or creates a table below the current one
	private Entry* getNextLevel(Entry* curTable, size_t entry, Flags flags, bool create) {
		// Check if the entry is marked as present
		if (curTable[entry] & 0x1) {
			return cast(Entry*)((curTable[entry] & ~(0xfff)) + PhysOffset);
		} else {
			if (!create)
				return null;
			
			// Allocate space for new table
			PmmResult result = newBlock(1);

			if (!result.isOkay)
				return null;

			// Set physical and return virtual
			curTable[entry] = cast(ulong)(result.unwrapResult) | flags;
			return cast(Entry*)(result.unwrapResult + PhysOffset);
		}
	}

}

//////////////////////////////
//         Instance         //
//////////////////////////////

private __gshared AddressSpace kernelSpace;

void initVmm(StivaleInfo* stivale) {
	writefln("\tIntializing Vmm:");

	// Get memory map
	RegionInfo info = RegionInfo(cast(MemMapTag*)(stivale.getTag(MemMapID)));

	// Alloc enough space for pml4 table
	PmmResult pml4Block = newBlock(1);

	if (!pml4Block.isOkay) 
		panic("Cannot allocate space for Pml4, init cannot continue");
	
	kernelSpace = AddressSpace(pml4Block.unwrapResult);
	log(2, "Pml4 block created: PhysAddress: %h", cast(ulong)(pml4Block.unwrapResult));

	// Map 2 GBs of the kernel
	for (size_t i = 0; i < 0x80000000; i += PageSize) {
		VmmResult result = kernelSpace.mapPage(cast(VirtAddress)(i + KernelBase), cast(PhysAddress)(i), Flags.Present 
		                                                                                              | Flags.Writeable);
		if (result != VmmResult.Good)
			panic("Not enough memory for Pml tables. Init cannot continue");
	}

	//panic("next:");

	// Map 4 GBs of memory
	for (size_t i = 0; i < 0x100000000; i += PageSize) {
		VmmResult result = kernelSpace.mapPage(cast(VirtAddress)(i + PhysOffset), cast(PhysAddress)(i), Flags.Present 
		                                                                                              | Flags.Writeable);
		if (result != VmmResult.Good)
			panic("Not enough memory for Pml tables. Init cannot continue");
	}
	//kernelSpace.setActive();

}