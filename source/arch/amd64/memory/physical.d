module arch.amd64.memory.physical;

/* OryxOS Amd64 Physical Memory Manager
 * This is oryxOS's physical memory manager, it allocates and frees physical memory
 * in 4kb blocks. This bitmap mappes all of the physical memory available
 * in 1 bitmap, this is done as it is the simplest approach.
 */

import lib.stivale;
import lib.std.math;
import lib.std.stdio;
import lib.std.result;

import core.atomic;
import common.memory;
import arch.amd64.memory;

private struct BitMap {
	ubyte* map;   // The actual bitmap
	ulong size;   // Size (bits) of the bitmap
	
	ulong nextFree;  // Next free block

	this(ubyte* map, ulong size) {
		this.map = map;
		this.size = size;
	}

	bool testBit(ulong bit) {
		assert(bit <= this.size);
		return !!(map[bit / 8] & (1 << (bit % 8)));
	}
	
	void setBit(ulong bit) {
		assert(bit <= this.size);
		this.map[bit / 8] |= (1 << (bit % 8));
	}

	void unsetBit(ulong bit) {
		assert(bit <= this.size);
		this.map[bit / 8] &= ~(1 << (bit % 8));
	}
}

//////////////////////////////
//         Instance         //
//////////////////////////////

private __gshared BitMap bitMap;

void initPmm(StivaleInfo* stivale) {
	writefln("\tIntializing Pmm:");

	// Get RegionInfo
	RegionInfo info = RegionInfo(cast(MemMapTag*)(stivale.getTag(MemMapID)));

	ulong mapSize;	// Bitmap size in bits

	// 1. Calculate size needed for bitmap
	ulong highestByte;
	for (ulong i = 0; i < info.count; i++) {
		auto immutable curRegion = info.regions[i];

		// We only work with Usable, Kernel and Bootloader regions
		if (curRegion.type != RegionType.Usable
			&& curRegion.type != RegionType.KernelOrModule
			&& curRegion.type != RegionType.BootloaderReclaimable)
			continue;

		// Actual calculation
		immutable ulong top = curRegion.base + curRegion.length;
		if (top > highestByte)
			highestByte = top;

		mapSize = divRoundUp(highestByte, PageSize) * 8; // `* 8` for bits
	}

	// 2. Find region large enough to fit bitmap
	for (ulong i = 0; i < info.count; i++) {
		auto curRegion = info.regions[i];

		// Get a Usable region big enough to fit the bitmap
		if (curRegion.type != RegionType.Usable || curRegion.length < mapSize * 8)
			continue;
		
		bitMap = BitMap(cast(ubyte*)(curRegion.base + PhysOffset), mapSize);

		// Reserve entire bitmap - Safer than setting entire bitmap as free
		bitMap.map[0..bitMap.size / 8] = 0xFF;

		// Update region info
		curRegion.base   += bitMap.size;
		curRegion.length -= bitMap.size;

		break; // Only need 1 region
	}

	// 3. Correctly populate the Bitmap with usable regions
	for (ulong i = 0; i < info.count; i++) {
		auto immutable curRegion = info.regions[i];

		if(curRegion.type != RegionType.Usable)
			continue;

		for (ulong j = 0; j < curRegion.length; j += PageSize) 
			bitMap.unsetBit((curRegion.base + j) / PageSize);
	}

	// 4. Set `nextFree` to the next available block
	for (ulong i = 0; i < bitMap.size; i++) {
		if (!bitMap.testBit(i)) {
			bitMap.nextFree = i;
			break;
		}
	}

	log(2, "Bitmap created and set :: Blocks accounted: %d Size: %h", bitMap.size, bitMap.size * 8);
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
PmmResult newBlock(ulong count) {													
	ulong regionStart = bitMap.nextFree;
									
	while (1) {
		bool  newRegionNeeded;												

		for (ulong i = regionStart; i < regionStart + count; i++) {
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

			// Set `nextFree` to the next free region
			if (bitMap.testBit(regionStart + count + 1)) {
				for (ulong i = regionStart + count + 1; i < bitMap.size; i++) {
					if (!bitMap.testBit(regionStart))
						bitMap.nextFree = i;
						break;
				}
			} else {
				bitMap.nextFree = regionStart + count;
			}

			return PmmResult(cast(PhysAddress)(regionStart * PageSize));
		}
	}
}

/// Frees `count` blocks of memory
/// Params:
/// 	blockStart = Physical address of the blocks
/// 	count = number of blocks to free
/// Returns: 
/// 	Physical Address to the start of the blocks
/// 	or an error
PmmResult delBlock(PhysAddress blockStart, ulong count) {
	// Check alignment
	if (cast(ulong)(blockStart) % PageSize != 0)
		return PmmResult(PmmError.AddressNotAligned);

	// Check block range
	if (cast(ulong)(blockStart) / PageSize + count > bitMap.size)
		return PmmResult(PmmError.BlockOutOfRange);

	// Determine the start
	ulong start = (cast(ulong)(blockStart) - PhysOffset) / PageSize;

	// Check if blocks have already been freed
	for (ulong i = start; i < start + count; i++)
		if (!bitMap.testBit(i))
			return PmmResult(PmmError.BlockAlreadyFreed);

	// Free the blocks
	for (ulong i = start; i < start + count; i++)
		bitMap.unsetBit(i);

	// Update `nextFree`
	if (bitMap.nextFree > start)
		bitMap.nextFree = start;

	return PmmResult(blockStart);
}