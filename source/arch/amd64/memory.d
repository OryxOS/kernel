module arch.amd64.memory;

import au.math;
import au.types;
import au.result;

import lib.limine;

import io.console;

import memory;
import memory.physical;

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

enum EntryFlags {                   // Table:       Description:
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

struct Pagemap {
	Entry* pml4;

	// Result variants
	enum Result {
		Good,
		NotEnoughSpaceForTables,
		PageAlreadyUnmapped,
	}

	this(void* init_blk) {
		assert(cast(ulong) init_blk % PageSize == 0);
		this.pml4 = cast(Entry*) (init_blk + PhysOffset);
	}

	void set_active() {
		auto root = cast(ulong) this.pml4 - PhysOffset;
		asm {
			mov RAX, root;
			mov CR3, RAX;
		}
	}

	void del_all_tables() {
		// Skip higher half - it is shared between all processes
		foreach (i; 0..256) {
			Entry* pml3 = get_next_level(pml4, i, EntryFlags.None, false);

			if (pml3 != null) {
				foreach (j; 0..512) {
					Entry* pml2 = get_next_level(pml3, j, EntryFlags.None, false);

					if (pml2 != null) {
						foreach (k; 0..512) {
							Entry* pml1 = get_next_level(pml2, k, EntryFlags.None, false);

							if (pml1 != null) {
								del_block(cast(void*) (cast(ulong) pml1 - PhysOffset));
							}
						}
						del_block(cast(void*) (cast(ulong) pml2 - PhysOffset));
					}
				}
				del_block(cast(void*) (cast(ulong) pml3 - PhysOffset));
			}
		}
		del_block(cast(void*) (cast(ulong) pml4 - PhysOffset));
	}

	/// Unmaps a Virtual address from a physical one
	/// Params:
	/// 	virtual = page-aligned virtual address
	/// Returns: Pagemap.Result varient
	Result unmap_page(void* virtual) {
		assert(cast(usize) virtual % PageSize == 0);

		// Find the PML1 entry
		Entry* pml1_entry = get_pml1_entry(virtual, EntryFlags.None, false);

		if (pml1_entry == null)
			return Pagemap.Result.PageAlreadyUnmapped;

		*pml1_entry = 0;

		return Pagemap.Result.Good;
	}

	/// Maps a Virtual address to a physical one
	/// Params:
	/// 	virtual  = page-aligned virtual address
	/// 	physical = page-aligned physical address
	/// 	flags    = the flags to map the page and all its levels with
	/// Returns: Pagemap.Result varient
	Result map_page(void* virtual, void* physical, EntryFlags flags) {
		//TODO: don't use assert, handle the error properly
		assert(cast(usize) physical % PageSize == 0);
		assert(cast(usize) virtual  % PageSize == 0);

		// Find or create the required pml tables
		Entry* pml1_entry = get_pml1_entry(virtual, flags, true);

		if (pml1_entry == null)
			return Pagemap.Result.NotEnoughSpaceForTables;

		*pml1_entry = cast(ulong) physical | flags;

		return Pagemap.Result.Good;
	}

	private Entry* get_pml1_entry(void* virtual, EntryFlags flags, bool create) {
		immutable ulong pml4_index = (cast(ulong) virtual & 0x1FFUL << 39) >> 39;
		immutable ulong pml3_index = (cast(ulong) virtual & 0x1FFUL << 30) >> 30;
		immutable ulong pml2_index = (cast(ulong) virtual & 0x1FFUL << 21) >> 21;
		immutable ulong pml1_index = (cast(ulong) virtual & 0x1FFUL << 12) >> 12;

		// Find or create the required Pml tables
		Entry* pml3 = get_next_level(pml4, pml4_index, flags, create);
		Entry* pml2 = get_next_level(pml3, pml3_index, flags, create);
		Entry* pml1 = get_next_level(pml2, pml2_index, flags, create);

		// Check we didn't run out of memory
		if (pml3 == null || pml2 == null || pml1 == null)
			return null;

		return cast(Entry*) &pml1[pml1_index];
	}
	
	// Finds or creates a table below the current one
	private Entry* get_next_level(Entry* table, usize entry, EntryFlags flags, bool create) {
		// Entry already exists
		if (table[entry] & 0x1)
			return cast(Entry*) ((table[entry] & ~(0xfff)) + PhysOffset);

		if (!create)
			return null;
			
		// Allocate space for new table
		PmmResult result = new_block(1);
		if (!result.is_good)
			return null;

		table[entry] = cast(ulong) result.unwrap_result() | flags; // Physical set
		return cast(Entry*) (result.unwrap_result() + PhysOffset); // Virtual returned
	}

}

//////////////////////////////
//         Instance         //
//////////////////////////////

__gshared Pagemap kernel_pm;

void init_vmm(MemoryMapResponse* map, KernelAddressResponse* k_addr) {
	kernel_pm = Pagemap(new_block()
	                    .unwrap_result("Cannot allocate space for Pml4, init cannot continue"));
	log(1, "Pml4 block allocated");

	/* Higher half needs to be shared amongst all processes, so it is
	 * necessary to initialise all entries
	 */
	foreach (i; 256..512) {
		Entry* res = 
			kernel_pm.get_next_level(kernel_pm.pml4, i, EntryFlags.Present | EntryFlags.Writeable, true);

		assert(res != null, "Not enough memory for Pml tables. Init cannot continue");
	}

	// Region 1 (Kernel):
	for (ulong  i = 0; i < 0x10000000; i += PageSize) {
		Pagemap.Result res = kernel_pm.map_page(cast(void*) i + k_addr.virtBase,
		                                    cast(void*) i + k_addr.physBase, 
											EntryFlags.Present | EntryFlags.Writeable);

		assert(res == Pagemap.Result.Good, "Not enough memory for Pml tables. Init cannot continue");
	}

	// Region 2 (Higher half):
	for (usize i = 0x1000; i < 0x100000000; i += PageSize) {
		Pagemap.Result res = kernel_pm.map_page(cast(void*) i + PhysOffset,
		                                    cast(void*) i, EntryFlags.Present | EntryFlags.Writeable);

		assert(res == Pagemap.Result.Good, "Not enough memory for Pml tables. Init cannot continue");
	}

	// Region 3 (All other memory map entries)
	foreach (i; 0..map.count) {
		auto entry = map.entries[i];

		auto base = align_down(entry.base, PageSize);
		auto top = align_up(entry.base + entry.length, PageSize);

		// Skip if already mapped
		if (top <= 0x100000000) continue;

		for (usize j = base; j < top; j += PageSize) {
			// Skip if already mapped
			if (j < 0x100000000) continue;
			
			Pagemap.Result res = kernel_pm.map_page(cast(void*) j + PhysOffset,
			                                   cast(void*) j, EntryFlags.Present | EntryFlags.Writeable);

			assert(res == Pagemap.Result.Good, "Not enough memory for Pml tables. Init cannot continue");
		}
	}

	kernel_pm.set_active();
	log(1, "New Pml tables loaded");
}

enum VmmError {
	NotEnoughMemory,
	AddressNotAligned,
	PageAlreadyFree,
}

alias VmmResult = Result!(void*, VmmError);

/// Returns `count` pages of memory (zeroed out if chosen)
/// Params:
/// 	count = number of blocks to allocate
/// Returns: 
/// 	Virtual address to the start of the pages
/// 	or an error
VmmResult new_page(usize count = 1, bool zero = true) {
	auto result = new_block(count, zero);

	if (result.is_good)
		return VmmResult(result.unwrap_result() + PhysOffset);
	else
		return VmmResult(cast(VmmError) result.unwrap_error());
}

/// Frees `count` pages of memory
/// Params:
/// 	pageStart = Virtual address of the blocks
/// 	count      = Number of blocks to free
/// Returns: 
/// 	Virtual address to the start of the pages
/// 	or an error
VmmResult del_page(void* pageStart, usize count) {
	auto result = del_page(pageStart, count);

	if (result.is_good)
		return VmmResult(result.unwrap_result() + PhysOffset);
	else
		return VmmResult(cast(VmmError) result.unwrap_error());
}