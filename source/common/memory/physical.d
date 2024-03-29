module commom.memory.physical;

/* OryxOS Amd64 Physical Memory Manager
 * This is oryxOS's physical memory manager, it allocates and frees physical memory
 * in 4kb blocks. This bitmap mappes all of the physical memory available
 * in one bitmap, this is done as it is the simplest approach.
 */

import lib.stivale;
import lib.util.math;
import lib.util.types;
import lib.util.result;
import lib.util.console;
import lib.util.bitmap;

import common.memory;
import common.memory.map;

// Cannot use PageSize - cyclical dependacies
version (X86_64) private enum BlockSize = 0x1000;

private __gshared BitMap bitMap;

void initPmm(StivaleInfo* stivale) {
	writefln("\nPmm Init:");

	auto info = RegionInfo(cast(MemMapTag*) stivale.getTag(MemMapID));

	// 1. Calculate size needed for bitmap
	usize highestByte;
	for (usize i = 0; i < info.count; i++) {
		immutable auto curRegion = info.regions[i];

		if (curRegion.type != RegionType.Usable
			&& curRegion.type != RegionType.KernelOrModule
			&& curRegion.type != RegionType.BootloaderReclaimable)
			continue;

		/* Regions cannot simply have their length added
		 * as memory will always have holes, so this
		 * method is used
		 */
		immutable usize top = curRegion.base + curRegion.length;
		if (top > highestByte)
			highestByte = top;

		bitMap.size = divRoundUp(highestByte, BlockSize) * 8;
	}

	// 2. Find region large enough to fit bitmap
	for (usize i = 0; i < info.count; i++) {
		immutable auto curRegion = info.regions[i];

		// Get a Usable region big enough to fit the bitmap
		if (curRegion.type != RegionType.Usable || curRegion.length < bitMap.size * 8)
			continue;
		
		bitMap.map = cast(ubyte*) (curRegion.base + PhysOffset);

		// Reserve entire bitmap - Safer than setting entire bitmap as free
		bitMap.map[0..bitMap.size / 8] = 0xFF;

		// Update region info
		info.regions[i].base   += bitMap.size;
		info.regions[i].length -= bitMap.size;
		
		log(1, "Bitmap created :: Blocks accounted: %d Size: %h", bitMap.size, bitMap.size * 8);

		break; // Only need 1 region
	}

	// 3. Correctly populate the Bitmap with usable regions
	for (usize i = 0; i < info.count; i++) {
		immutable auto curRegion = info.regions[i];


		if(curRegion.type != RegionType.Usable)
			continue;

		for (usize j = 0; j < curRegion.length; j += BlockSize) 
			bitMap.unsetBit((curRegion.base + j) / BlockSize);
	}

	// 4. Set `bitMap.nextFree` to the next available block
	for (usize i = 0; i < bitMap.size; i++) {
		if (!bitMap.testBit(i)) {
			bitMap.nextFree = i;
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
alias PmmResult = Result!(PhysAddress, PmmError);

/// Returns `count` blocks of memory (zeroed out if chosen)
/// Params:
/// 	count = number of blocks to allocate
/// Returns: 
/// 	Physical address to the start of the blocks
/// 	or an error
PmmResult newBlock(usize count = 1, bool zero = true) {													
	usize regionStart = bitMap.nextFree;
	while (1) {
		bool  newRegionNeeded;												

		for (usize i = regionStart; i < regionStart + count; i++) {
			if (i >= bitMap.size) 
				return PmmResult(PmmError.NotEnoughMemory);

			if (!bitMap.testBit(i))
				continue;

			// Necessary to find a new region
			regionStart = i;
			newRegionNeeded = true;
			break;
		}
		
		// Check the result - is a new region needed
		if (newRegionNeeded) {
			for (; regionStart < bitMap.size; regionStart++) {
				if (!bitMap.testBit(regionStart))
					break;

				if (regionStart == bitMap.size) {
					return PmmResult(PmmError.NotEnoughMemory);
				}
			}
		} else {
			// Mark region as reserved
			foreach (i; regionStart..regionStart + count) {
				bitMap.setBit(i);
			}

			// Zero if asked to
			if (zero) {
				ubyte* region = cast(ubyte*) (regionStart * BlockSize + PhysOffset);
				region[0..(count * BlockSize)] = 0;
			}

			// Set `bitMap.nextFree` to the next free region
			usize i;
			for (i = regionStart + count; i < bitMap.size; i++) {
				if (!bitMap.testBit(i)) {
					bitMap.nextFree = i;
					return PmmResult(cast(PhysAddress) (regionStart * BlockSize));
				}
			}
			if (i == bitMap.size) {
				bitMap.full = true;
				return PmmResult(cast(PhysAddress) (regionStart * BlockSize));
			}
		}
	}
}

/// Frees `count` blocks of memory
/// Params:
/// 	blockStart = Physical address of the blocks
/// 	count      = Number of blocks to free
/// Returns: 
/// 	Physical address to the start of the blocks
/// 	or an error
PmmResult delBlock(PhysAddress blockStart, usize count) {
	// Safety checks
	if (cast(usize) blockStart % BlockSize != 0)
		return PmmResult(PmmError.AddressNotAligned);
	if (cast(usize) blockStart / BlockSize + count > bitMap.size)
		return PmmResult(PmmError.BlockOutOfRange);

	usize start = (cast(usize) blockStart) / BlockSize;

	for (usize i = start; i < start + count; i++)
		if (!bitMap.testBit(i))
			return PmmResult(PmmError.BlockAlreadyFreed);

	for (usize i = start; i < start + count; i++)
		bitMap.unsetBit(i);

	if (bitMap.nextFree > start)
		bitMap.nextFree = start;

	return PmmResult(blockStart);
}