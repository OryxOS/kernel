module arch.amd64.memory;

import lib.std.stdio;
import lib.std.result;

import common.memory;
import common.memory.physical;

/* OryxOS Amd64 Virtual Memory Manager
 *
 * Terms:
 *      Pml4 : Top-level paging table    Loaded into Cr4        512 pointers to Pml3 Tables
 *      Pml3 : Level down                                       512 pointers to Pml2 Tables
 *      Pml2 : Level down                                       512 pointers to Pml1 Tables
 *      Pml1 : Level down                                       512 pointers to Pages
 *      Page : 4 kilobytes of memory
 *
 * All tables must be 4kb-aligned. The best way to do this is to allocate a block of
 * physical memory for each Table. Currently this Vmm only supports 4 level paging,
 * however this will change in the future once 5 level paging is more widely supported
 */

enum PageSize = 0x1000;                  // Standard x86 page size (4kb)

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

	None            = 0,

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

	PageAlreadyUnmapped
}

struct AddressSpace {
	private Entry* pml4;

	this(PhysAddress pml4Block) {
		assert(cast(ulong)(pml4Block) % PageSize == 0);
		this.pml4 = cast(Entry*)(pml4Block + PhysOffset);
	}

	void setActive() {
		auto root = cast(ulong)(this.pml4) - PhysOffset;
		asm {
			mov RAX, root;
			mov CR3, RAX;
		}
	}

	/// Unmaps a Virtual address from a physical one
	/// Params:
	/// 	virtual = page-aligned virtual address
	/// Returns: VmmResult varient
	VmmResult unmapPage(VirtAddress virtual) {
		assert(cast(size_t)(virtual)  % PageSize == 0);

		// Find the Pml1Entry
		Entry* pml1Entry = getPml1Entry(virtual, Flags.None, false);

		if (pml1Entry == null)
			return VmmResult.PageAlreadyUnmapped;

		*pml1Entry = 0;

		return VmmResult.Good;
	}

	/// Maps a Virtual address to a physical one
	/// Params:
	/// 	virtual  = page-aligned virtual address
	/// 	physical = page-aligned physical address
	/// 	flags    = the flags to map the page and all its levels with
	/// Returns: VmmResult varient
	VmmResult mapPage(VirtAddress virtual, PhysAddress physical, Flags flags) {
		assert(cast(size_t)(physical) % PageSize == 0);
		assert(cast(size_t)(virtual)  % PageSize == 0);

		// Find or create the required pml tables
		Entry* pml1Entry = getPml1Entry(virtual, flags, true);

		if (pml1Entry == null)
			return VmmResult.NotEnoughSpaceForTables;

		*pml1Entry = cast(ulong)(physical) | flags;

		return VmmResult.Good;
	}

	private Entry* getPml1Entry(VirtAddress virtual, Flags flags, bool create) {
		immutable ulong pml4Index = (cast(ulong)(virtual) & 0x1FFUL << 39) >> 39;
		immutable ulong pml3Index = (cast(ulong)(virtual) & 0x1FFUL << 30) >> 30;
		immutable ulong pml2Index = (cast(ulong)(virtual) & 0x1FFUL << 21) >> 21;
		immutable ulong pml1Index = (cast(ulong)(virtual) & 0x1FFUL << 12) >> 12;

		// Find or create the required Pml tables
		Entry* pml3 = getNextLevel(this.pml4, pml4Index, flags, create);
		Entry* pml2 = getNextLevel(pml3, pml3Index, flags, create);
		Entry* pml1 = getNextLevel(pml2, pml2Index, flags, create);

		// Check we didn't run out of memory
		if (pml3 == null || pml2 == null || pml1 == null)
			return null;

		return cast(Entry*)(&pml1[pml1Index]);
	}
	
	// Finds or creates a table below the current one
	private Entry* getNextLevel(Entry* curTable, size_t entry, Flags flags, bool create) {
		// Entry already exists
		if (curTable[entry] & 0x1)
			return cast(Entry*)((curTable[entry] & ~(0xfff)) + PhysOffset);

		if (!create)
			return null;
			
		// Allocate space for new table
		PmmResult result = newBlock(1);
		if (!result.isOkay)
			return null;

		curTable[entry] = cast(ulong)(result.unwrapResult) | flags; // Physical set
		return cast(Entry*)(result.unwrapResult + PhysOffset);      // Virtual returned
	}

}

//////////////////////////////
//         Instance         //
//////////////////////////////

__gshared AddressSpace kernelSpace;

void initVmm() {
	writefln("\tIntializing Vmm:");

	kernelSpace = AddressSpace(newBlock(1)
	                          .unwrapResult("Cannot allocate space for Pml4, init cannot continue"));
	log(2, "Pml4 block allocated");

	/* Regions:
	 * 1. Physical: 0000000000000000-0000000100000000 Virtual: 0000000000000000-0000000100000000 - pw
	 * 2. Physical: 0000000000000000-0000000100000000 Virtual: ffff800000000000-ffff800100000000 - pw
	 * 3. Physical: 0000000000000000-0000000080000000 Virtual: ffffffff80000000-ffffffffffffffff - pw
	 */

	// Region 1 and 2
	for (size_t i = 0; i < 0x100000000; i += PageSize) {
		VmmResult map1 = kernelSpace.mapPage(cast(VirtAddress)(i + PhysOffset),
		                                     cast(PhysAddress)(i), Flags.Present | Flags.Writeable);

		VmmResult map2 = kernelSpace.mapPage(cast(VirtAddress)(i),
		                                     cast(PhysAddress)(i), Flags.Present | Flags.Writeable);

		if (map1 != VmmResult.Good || map2 != VmmResult.Good)
			panic("Not enough memory for Pml tables. Init cannot continue");
	}

	// Region 3
	for (size_t i = 0; i < 0x80000000; i += PageSize) {
		VmmResult map = kernelSpace.mapPage(cast(VirtAddress)(i + KernelBase),
		                                    cast(PhysAddress)(i), Flags.Present | Flags.Writeable);
		if (map != VmmResult.Good)
			panic("Not enough memory for Pml tables. Init cannot continue");
	}

	kernelSpace.setActive();

	log(2, "New Pml tables loaded");
}