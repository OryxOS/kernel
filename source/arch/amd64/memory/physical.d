module arch.amd64.memory.physical;

/* OryxOS Bitmap Physical Allocator
 * This is oryxOS's bitmap allocator, it allocates physical memory
 * in 4kb blocks. This bitmap mappes all of the physical memory available
 * in 1 bitmap. This is done as it is the simplest approach
 */

import arch.amd64.memory;
import specs.stivale;
import common.memory;
import runtime.math;
import core.atomic;
import io.console;

private struct BitMap {
	byte* map;          // The actual bitmap
	ulong size;         // Size (bits) of the bitmap

	shared bool testBit(ulong bit) {
		assert(bit <= this.size);
		return this.map[bit * 8] >> (bit % 8) & 1;
	}
	
	shared void setBit(ulong bit) {
		assert(bit <= this.size);
		atomicOp!"|="(this.map[bit * 8], 1 << (bit % 8));
	}

	shared void unsetBit(ulong bit) {
		assert(bit <= this.size);
		atomicOp!"|="(this.map[bit * 8], 0 << (bit % 8));
	}
}

shared BitMap bitMap;

 void initPmm(StivaleInfo* stivale) {
	writeln("\tIntializing Pmm:");

	// Get RegionInfo
	RegionInfo info = RegionInfo(cast(MemMapTag*)(stivale.getTag(MemMapID)));

	ulong mapSize;	// Bitmap size in bits

	// 1. Calculate size needed for bitmap
	ulong highestByte;
	for (ulong i = 0; i < info.count; i++) {
		auto curRegion = info.regions[i];

		// We only work with Usable, Kernel and Bootloader regions
		if (curRegion.type != RegionType.Usable
			&& curRegion.type != RegionType.KernelOrModule
			&& curRegion.type != RegionType.BootloaderReclaimable)
			continue;

		// Actual calculation
		ulong top = curRegion.base + curRegion.length;
		if (top > highestByte)
			highestByte = top;

		mapSize = divRoundUp(highestByte, PageSize) / 8; // `/ 8` for bits
	}

	// 2. Find region large enough to fit bitmap
	for (ulong i = 0; i < info.count; i++) {
		auto curRegion = info.regions[i];

		// Get a Usable region big enough to fit the bitmap
		if (curRegion.type != RegionType.Usable || curRegion.length < mapSize * 8)
			continue;
		
		bitMap = shared BitMap(cast(shared byte*)(curRegion.base + PhysOffset), mapSize);

		// Reserve entire bitmap
		bitMap.map[0..bitMap.size * 8] = 0xf;

		// Update region info
		curRegion.base   += bitMap.size;
		curRegion.length -= bitMap.size;

		log(2, "Bitmap created :: Blocks accounted: %d Size: %h", bitMap.size, bitMap.size * 8);

		break; // Only need 1
	}
 }