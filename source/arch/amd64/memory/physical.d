module arch.amd64.memory.physical;

/* OryxOS Bitmap Physical Allocator
 * This is oryxOS's bitmap allocator, it allocates physical memory
 * in 4kb blocks. This bitmap mappes all of the physical memory available
 */

import arch.amd64.memory;
import specs.stivale;
import common.memory;
import io.console;

 struct BitMap {
	ubyte* bits;  // Accounting space
	ulong size;   // Size of the accounting space

	void setBlock(int id);
	bool getBlock(int id);
 }

 private shared BitMap bitMap;

/* This function essentailly takes the Stivale Memory Map
 * and creates a bitmap from it. First we find a space big
 * to fit the bitmap. Then onto that bitmap we mark all the
 * areas not maked as Usable in the Memory Map as reserved
 */
 void initPmm(StivaleInfo* stivale) {
	writeln("    Intializing Pmm:");

	// Get RegionInfo
	RegionInfo info = RegionInfo(cast(MemMapTag*)(stivale.getTag(MemMapID)));

	// Calculate total memory amount. This only includes reclaimable, usable and kernel regions
	ulong memTotal;
	foreach (i; 0..info.count) {
		if (info.regions[i].type == RegionType.Usable || 
			info.regions[i].type == RegionType.BootloaderReclaimable || 
			info.regions[i].type == RegionType.KernelOrModule ||
			info.regions[i].type == RegionType.AcpiReclaimable) {
			memTotal += info.regions[i].length;
		}
	}
	log(LogLevel.Info, 2, "Total Physical memory: ", memTotal / 1024 / 1024, " mb");

	// Iterate through the regions, finding one suitable to hold our bitmap
	foreach (i; 0..info.count){
		immutable auto curRegion = info.regions[i];

		// Check Type and Size
		if (curRegion.type == RegionType.Usable && curRegion.length >= memTotal / PageSize / 8) {
			// Logging
			immutable ulong rem = curRegion.length - memTotal / PageSize / 8;
			log(LogLevel.Info, 2, "Found free region for Bitmap: Size: ", curRegion.length, " Remainder: ", rem);

			// Set our global BitMap
			bitMap = shared BitMap(cast(shared ubyte*)(curRegion.base), memTotal / PageSize / 8);
			log(LogLevel.Info, 2, "BitMap set and ready for use");
			break;
		}
	}

	// Mark used areas
 }