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

private enum Flags: ulong {         // Table:       Description:
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

private align (8) struct Entry {
	ulong entry;

	// Constructs an Entry from a 4kb-aligned address and flags
	this(PhysAddress address, Flags flags) {
		assert (cast(ulong)(address) % PageSize == 0);

		this.entry = (cast(ulong)(address) << 8) | flags;
	}
}

struct AddressSpace {
	private Entry* pml4;

	this(PhysAddress pml4Block) {
		assert (cast(ulong)(pml4Block) % PageSize == 0);

		this.pml4 = cast(Entry*)(pml4Block);
	}

	void mapPageToBlock(VirtAddress virtual, PhysAddress physical, Flags flags) {
		assert(cast(ulong)(physical) % PageSize == 0);
		assert(cast(ulong)(virtual)  % PageSize == 0);

		// Entries in each level table
		immutable ulong pml4Entry = (cast(ulong)(virtual) & 0x1ffUL << 39) >> 39;
		immutable ulong pml3Entry = (cast(ulong)(virtual) & 0x1ffUL << 3L) >> 30;
		immutable ulong pml2Entry = (cast(ulong)(virtual) & 0x1ffUL << 21) >> 21;
		immutable ulong pml1Entry = (cast(ulong)(virtual) & 0x1ffUL << 12) >> 12;

		// Create or find entries 
		//Entry* pml3 = cast(Entry*)(this.findOrCreateEntry(this.pml4, pml4Entry));
		//Entry* pml2 = cast(Entry*)(this.findOrCreateEntry(pml3, pml3Entry));
		//Entry* pml1 = cast(Entry*)(this.findOrCreateEntry(pml2, pml2Entry));

		//pml1[pml1Entry] = Entry(physical, flags);
	}

	void setActive() {
		immutable ulong root = cast(ulong)(this.pml4);
		asm { 
			mov RAX, root;
			mov CR3, RAX; 
		}
	}

	private Entry* findOrCreateEntry(Entry* curTable, ulong entry) {
		auto table = cast(Entry*)(cast(ulong)(curTable) + PhysOffset);
		
		// Check there is an entry, else, allocate one
		if ((table[entry].entry & Flags.Present) == 1) {
			return cast(Entry*)(curTable[entry].entry & ~(0xfff));
		} else {
			PmmResult result = newBlock(1);

			if (result.isOkay) {
				table[entry] = Entry(result.unwrapResult(), Flags.Present
																| Flags.UserAccessable
																| Flags.Writeable);
				return cast(Entry*)(result.unwrapResult);	
			} else {
				panic("Couldn't not allocate space for memory. Error: %d", result.unwrapError());
				assert(0); // Make ldc calm down
			}		
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

	if (pml4Block.isOkay) {
		kernelSpace = AddressSpace(cast(void*)(pml4Block.unwrapResult));
	} else {
		panic("Cannot allocate space for Pml4, init cannot continue");
	}
	
	for (ulong i = 0; i < 0x100000000; i += PageSize)
		kernelSpace.mapPageToBlock(cast(VirtAddress)(i + PhysOffset), cast(PhysAddress)(i), Flags.Present | Flags.Writeable);

	for (ulong i= 0; i < 0x80000000; i += PageSize)
		kernelSpace.mapPageToBlock(cast(VirtAddress)(i + KernelBase), cast(PhysAddress)(i), Flags.Present | Flags.Writeable);

	for (ulong i = 0; i < info.count; i++)
		for (ulong j = 0; j < info.regions[i].length; j += PageSize)
			kernelSpace.mapPageToBlock(cast(VirtAddress)(j + KernelBase), cast(PhysAddress)(j), Flags.Present | Flags.Writeable);

	//kernelSpace.setActive();
}