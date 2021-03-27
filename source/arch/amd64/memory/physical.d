module arch.amd64.memory.physical;

/* OryxOS Bitmap Physical Allocator
 * This is oryxOS's bitmap allocator, it allocates physical memory
 * in 4kb blocks. This bitmap mappes all of the physical memory available
 */

import arch.amd64.memory;
import specs.stivale;
import common.memory;
import core.atomic;
import io.console;

struct BlockInfo {
	ulong address;  // Address where the block starts
	bool  reserved; // Has the block been reserved 
}

struct BitMap {
	ubyte* bits;  // Accounting space
	ulong  size;  // Size of the accounting space

	// Set a block as either reserved or avialable
	shared void setBlock(ulong id, bool val);

	// Returns a BlockInfo struct
	shared BlockInfo getBlock(ulong id);
}

 private shared BitMap bitMap;

/* This function essentailly takes the Stivale Memory Map
 * and creates a bitmap from it. First we find a space big
 * to fit the bitmap. Then onto that bitmap we mark all the
 * areas not maked as Usable in the Memory Map as reserved
 */
 void initPmm(StivaleInfo* stivale) {
	writeln("\tIntializing Pmm:");

	// Get RegionInfo
	RegionInfo info = RegionInfo(cast(MemMapTag*)(stivale.getTag(MemMapID)));

	foreach(i; 0..info.count) {
		immutable auto curRegion = info.regions[i];
		log(2, "Region :: Base: %h\tLength: %h", curRegion.base, curRegion.length);
	}

	// Calculate total memory amount, This included MMIO and stuff
	ulong memTotal = info.regions[info.count - 1].base + info.regions[info.count - 1].length;
	log(2, "Total addressable memory: %d mb", memTotal / 1024 / 1024);

	// Iterate through the regions, finding one suitable to hold our bitmap
	foreach (i; 0..info.count){
		immutable auto curRegion = info.regions[i];

		// Check Type and Size
		if (curRegion.type == RegionType.Usable && curRegion.length >= memTotal / PageSize / 8) {
			// Logging
			log(2, "Found free region for Bitmap :: Base: %h\tLength: %h\tUsed: %h", curRegion.base, curRegion.length, memTotal / PageSize / 8);

			// Set our global BitMap
			bitMap = shared BitMap(cast(shared ubyte*)(curRegion.base), memTotal / PageSize / 8);
			log(2, "BitMap set and ready for use");
			break;
		}
	}
 }