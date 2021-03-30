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
	ubyte* map;   // The actual bitmap
	ulong size;   // Size (bits) of the bitmap
	
	ulong nextFree;  // Next free block

	shared this(shared ubyte* map, shared ulong size) {
		this.map = map;
		this.size = size;
	}

	shared bool testBit(ulong bit) {
		assert(bit <= this.size);
		return !!(map[bit / 8] & (1 << (bit % 8)));
	}
	
	shared void setBit(ulong bit) {
		assert(bit <= this.size);
		atomicOp!"|="(this.map[bit / 8], (1 << (bit % 8)));
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

	// Display some bits
	writefln("\nBitmaap:");
	foreach(i; 0..0x100 + 0x100) {
		if (bitMap.testBit(i)) {
			writef("%d", 1);
		} else {
			writef("0");
		}
	}
	writefln("");

	//log(2, "Bitmap created and set :: Blocks accounted: %d Size: %h", bitMap.size, bitMap.size * 8);
 }

 // Error handling
enum PmmError{
	OutOfMemory,
	NoRegionLargeEnough,
	
	BlockAlreadyFreed,
}
alias PmmResult = Result!(void*, PmmError);

PmmResult newBlock(ulong count) {
	ulong regionStart = bitMap.nextFree;

	writefln("regionStart: %d", regionStart);
	
	while (1) {
		bool  newRegionNeeded;

		for (ulong i = regionStart; i < regionStart + count; i++) {
			if (!bitMap.testBit(i))
				continue;

			// Necessary to find a new region
			regionStart = i;
			newRegionNeeded = true;
			break;
		}

		if (newRegionNeeded) {
			for (; regionStart < bitMap.size; regionStart++) {
				if (!bitMap.testBit(regionStart))
					break;

				if (regionStart == bitMap.size) {
					return PmmResult(PmmError.OutOfMemory);
				}
			}
			// End of memory
			return PmmResult(PmmError.NoRegionLargeEnough);
		} else {
			// Success

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
				bitMap.nextFree = regionStart + count + 1;
			}

			return PmmResult(cast(void*)(regionStart * PageSize + PhysOffset));
		}
	}
}