module memory.physical;

/* OryxOS Amd64 Physical Memory Manager
 * This is oryxOS's physical memory manager, it allocates and frees physical memory
 * in 4kb blocks. This bitmap mappes all of the physical memory available
 * in one bitmap, this is done as it is the simplest approach.
 */

import lib.limine;
import au.math;
import au.types;
import au.result;
import io.console;
import au.bitmap;

import memory;

// Cannot use PageSize - cyclical dependacies
version (X86_64) private enum BlockSize = 0x1000;

private __gshared BitMap bitmap;

void init_pmm(MemoryMapResponse* map) {
	writefln("\nPmm Init:");

	// 1. Calculate size needed for bitmap
	usize top_byte = 0;
	for (usize i = 0; i < map.count; i++) {
		auto entry = map.entries[i];

		if (entry.type != MemoryMapType.Usable && entry.type != MemoryMapType.BootloaderReclaimable)
			continue;

		/* Entries cannot simply have their length added
		 * as memory will always have holes, so this
		 * method is used
		 */
		immutable usize top = entry.base + entry.length;
		if (top > top_byte)
			top_byte = top;

		bitmap.size = div_round_up(top_byte, BlockSize) * 8;
	}

	// 2. Find entry large enough to fit bitmap
	for (usize i = 0; i < map.count; i++) {
		auto entry = map.entries[i];

		// Find a free entry big enough to fit the bitmap
		if (entry.type != MemoryMapType.Usable || entry.length < bitmap.size * 8)
			continue;
		
		bitmap.map = cast(ubyte*) (entry.base + PhysOffset);

		// Reserve entire bitmap - Safer than setting entire bitmap as free
		bitmap.map[0..bitmap.size / 8] = 0xFF;

		// Update memory map
		map.entries[i].base   += bitmap.size;
		map.entries[i].length -= bitmap.size;
		
		log(1, "Bitmap created :: Blocks accounted: %d Size: %h", bitmap.size, bitmap.size * 8);

		break;
	}

	// 3. Correctly populate the bitmap with usable entries
	for (usize i = 0; i < map.count; i++) {
	auto entry = map.entries[i];


		if(entry.type != MemoryMapType.Usable) continue;

		for (usize j = 0; j < entry.length; j += BlockSize) 
			bitmap.unset_bit((entry.base + j) / BlockSize);
	}

	// 4. Set `bitmap.next_free` to the next available block
	for (usize i = 0; i < bitmap.size; i++) {
		if (!bitmap.test_bit(i)) {
			bitmap.next_free = i;
			break;
		}
	}

	log(1, "Bitmap fully populated and ready for use");
 }

// Error handling
enum PmmError {
	NotEnoughMemory,
	AddressNotAligned,	
	BlockAlreadyFreed,
	BlockOutOfRange,
}
alias PmmResult = Result!(void*, PmmError);

/// Returns `count` blocks of memory (zeroed out if chosen)
/// Params:
/// 	count = number of blocks to allocate
/// Returns: 
/// 	Physical address to the start of the blocks
/// 	or an error
PmmResult new_block(usize count = 1, bool zero = true) {													
	usize start = bitmap.next_free;
	while (1) {
		bool  new_needed;												

		for (usize i = start; i < start + count; i++) {
			if (i >= bitmap.size) 
				return PmmResult(PmmError.NotEnoughMemory);

			if (!bitmap.test_bit(i)) continue;

			// Necessary to find a new entry
			start = i;
			new_needed = true;
			break;
		}
		
		// Check the result - is a new entry needed
		if (new_needed) {
			// TODO: replace with foreach
			for (; start < bitmap.size; start++) {
				if (!bitmap.test_bit(start))
					break;

				if (start == bitmap.size) {
					return PmmResult(PmmError.NotEnoughMemory);
				}
			}
		} else {
			// Mark entry as reserved
			foreach (i; start..start + count) {
				bitmap.set_bit(i);
			}

			// Zero if asked to
			if (zero) {
				ubyte* entry = cast(ubyte*) (start * BlockSize + PhysOffset);
				entry[0..(count * BlockSize)] = 0;
			}

			// Set `bitmap.next_free` to the next free entry
			usize i;
			for (i = start + count; i < bitmap.size; i++) {
				if (!bitmap.test_bit(i)) {
					bitmap.next_free = i;
					return PmmResult(cast(void*) (start * BlockSize));
				}
			}
			if (i == bitmap.size) {
				bitmap.full = true;
				return PmmResult(cast(void*) (start * BlockSize));
			}
		}
	}
}

/// Frees `count` blocks of memory
/// Params:
/// 	start = Physical address of the blocks
/// 	count = Number of blocks to free
/// Returns: 
/// 	Physical address to the start of the blocks
/// 	or an error
PmmResult del_block(void* b_start, usize count = 1) {
	// Safety checks
	if (cast(usize) b_start % BlockSize != 0)
		return PmmResult(PmmError.AddressNotAligned);
	if (cast(usize) b_start / BlockSize + count > bitmap.size)
		return PmmResult(PmmError.BlockOutOfRange);

	usize start = (cast(usize) b_start) / BlockSize;

	for (usize i = start; i < start + count; i++)
		if (!bitmap.test_bit(i))
			return PmmResult(PmmError.BlockAlreadyFreed);

	for (usize i = start; i < start + count; i++)
		bitmap.unset_bit(i);

	if (bitmap.next_free > start)
		bitmap.next_free = start;

	return PmmResult(b_start);
}