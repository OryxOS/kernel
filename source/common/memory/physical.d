module commom.memory.physical;

/* OryxOS Amd64 Physical Memory Manager
 * This is oryxOS's physical memory manager, it allocates and frees physical memory
 * in 4kb blocks. This bitmap mappes all of the physical memory available
 * in one bitmap, this is done as it is the simplest approach.
 */

import lib.stivale;
import lib.std.math;
import lib.std.stdio;
import lib.std.result;
import lib.std.bitmap;

import common.memory;
import common.memory.map;

version (X86_64) enum BlockSize = 0x1000;

private __gshared BitMap bitMap;

void initPmm(StivaleInfo* stivale) {
	writefln("\nPmm Init:");

	auto info = RegionInfo(cast(MemMapTag*)(stivale.getTag(MemMapID)));

	// 1. Calculate size needed for bitmap
	size_t highestByte;
	for (size_t i = 0; i < info.count; i++) {
		auto immutable curRegion = info.regions[i];

		if (curRegion.type != RegionType.Usable
			&& curRegion.type != RegionType.KernelOrModule
			&& curRegion.type != RegionType.BootloaderReclaimable)
			continue;

		/* Regions cannot simply have their length added
		 * as memory will always have holes, so this
		 * method is used
		 */
		immutable size_t top = curRegion.base + curRegion.length;
		if (top > highestByte)
			highestByte = top;

		bitMap.size = divRoundUp(highestByte, BlockSize) * 8;
	}

	// 2. Find region large enough to fit bitmap
	for (size_t i = 0; i < info.count; i++) {
		immutable auto curRegion = info.regions[i];

		// Get a Usable region big enough to fit the bitmap
		if (curRegion.type != RegionType.Usable || curRegion.length < bitMap.size * 8)
			continue;
		
		bitMap.map = cast(ubyte*)(curRegion.base + PhysOffset);

		// Reserve entire bitmap - Safer than setting entire bitmap as free
		bitMap.map[0..bitMap.size / 8] = 0xFF;

		// Update region info
		info.regions[i].base   += bitMap.size;
		info.regions[i].length -= bitMap.size;
		
		log(1, "Bitmap created :: Blocks accounted: %d Size: %h", bitMap.size, bitMap.size * 8);

		break; // Only need 1 region
	}

	// 3. Correctly populate the Bitmap with usable regions
	for (size_t i = 0; i < info.count; i++) {
		auto immutable curRegion = info.regions[i];

		if(curRegion.type != RegionType.Usable)
			continue;

		for (size_t j = 0; j < curRegion.length; j += BlockSize) 
			bitMap.unsetBit((curRegion.base + j) / BlockSize);
	}

	// 4. Set `bitMap.nextFree` to the next available block
	for (size_t i = 0; i < bitMap.size; i++) {
		if (!bitMap.testBit(i)) {
			bitMap.nextFree = i;
			break;
		}
	}

	log(1, "Bitmap fully populated and ready for use");
 }

// Error handling
enum PmmError{
	NotEnoughMemory,

	AddressNotAligned,	
	BlockAlreadyFreed,
	BlockOutOfRange,
}
alias PmmResult = Result!(PhysAddress, PmmError);

/// Returns `count` blocks of zeroed out memory
/// Params:
/// 	count = number of blocks to allocate
/// Returns: 
/// 	Physical Address to the start of the blocks
/// 	or an error
PmmResult newBlock(size_t count = 1, bool zero = true) {													
	size_t regionStart = bitMap.nextFree;
	while (1) {
		bool  newRegionNeeded;												

		for (size_t i = regionStart; i < regionStart + count; i++) {
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
				ubyte* region = cast(ubyte*)(regionStart * BlockSize + PhysOffset);
				region[0..(count * BlockSize)] = 0;
			}

			// Set `bitMap.nextFree` to the next free region
			size_t i;
			for (i = regionStart + count; i < bitMap.size; i++) {
				if (!bitMap.testBit(i)) {
					bitMap.nextFree = i;
					return PmmResult(cast(PhysAddress)(regionStart * BlockSize));
				}
			}
			if (i == bitMap.size) {
				bitMap.full = true;
				return PmmResult(cast(PhysAddress)(regionStart * BlockSize));
			}
		}
	}
}

/// Frees `count` blocks of memory
/// Params:
/// 	blockStart = Physical address of the blocks
/// 	count      = Number of blocks to free
/// Returns: 
/// 	Physical Address to the start of the blocks
/// 	or an error
PmmResult delBlock(PhysAddress blockStart, size_t count) {
	// Safety checks
	if (cast(size_t)(blockStart) % BlockSize != 0)
		return PmmResult(PmmError.AddressNotAligned);
	if (cast(size_t)(blockStart) / BlockSize + count > bitMap.size)
		return PmmResult(PmmError.BlockOutOfRange);

	size_t start = (cast(size_t)(blockStart)) / BlockSize;

	for (size_t i = start; i < start + count; i++)
		if (!bitMap.testBit(i))
			return PmmResult(PmmError.BlockAlreadyFreed);

	for (size_t i = start; i < start + count; i++)
		bitMap.unsetBit(i);

	if (bitMap.nextFree > start)
		bitMap.nextFree = start;

	return PmmResult(blockStart);
}