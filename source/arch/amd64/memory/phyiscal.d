module arch.amd64.memory.phyiscal;

import specs.stivale;
import common.memory;

/* OryxOS Bitmap Physical Allocator
 * This is oryxOS's bitmap allocator, it allocates physical memory
 * in 4kb blocks.
 */

// Linked list design Bitmap
 struct BitMap {
	 ubyte[] bits;  // Accounting space

	 void setBlock(int id);
	 bool getBlock(int id);
 }

 /* We create our own Memory map stuff for
  * 2 reasons, Firstly, independance and secondly
  * this allows us to design the allocator more to
  * our liking
  */

 void initPmm(StivaleInfo* stivale) {
	 // Get RegionInfo
	 RegionInfo info = RegionInfo(cast(MemMapTag*)(stivale.getTag(MemMapID)));

	 foreach (i; 0..info.count){
		 
	 }
 }
 