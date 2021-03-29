module arch.amd64.memory.physical;

/* OryxOS Bitmap Physical Allocator
 * This is oryxOS's bitmap allocator, it allocates physical memory
 * in 4kb blocks. This bitmap mappes all of the physical memory available
 * in 1 bitmap. This is done as it is the simplest approach
 */

import lib.stivale;
import lib.std.math;
import lib.std.stdio;
import lib.std.result;

import core.atomic;
import common.memory;
import arch.amd64.memory;

private struct BitMap {
	ubyte* map;          // The actual bitmap
	ulong size;          // Size (bits) of the bitmap

	shared bool testBit(ulong bit) {
		assert(bit <= this.size);

		if ((this.map[bit / 8] & (1 << (bit % 8))) == 1) {
			return true;
		} else {
			return false;
		}
	}
	
	shared void setBit(ulong bit) {
		assert(bit <= this.size);
		atomicOp!"|="(this.map[bit / 8], 1 << (bit % 8));
	}

	shared void unsetBit(ulong bit) {
		assert(bit <= this.size);
		atomicOp!"&="(this.map[bit / 8], ~(1 << (bit % 8)));
	}
}

//////////////////////////////
//         Instance         //
//////////////////////////////

shared BitMap bitMap;

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
		
		bitMap = shared BitMap(cast(shared ubyte*)(curRegion.base + PhysOffset), mapSize);

		// Reserve entire bitmap - Safer than setting entire bitmap as free
		bitMap.map[0..bitMap.size * 8] = 0xFF;

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

	log(2, "Bitmap created and set :: Blocks accounted: %d Size: %h", bitMap.size, bitMap.size * 8);
 }