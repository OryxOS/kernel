module common.memory.alloc.bitslab;

/* OryxOS BitSlab (Bitmap + Slab) Allocator
 * The BitSlab allocator consists of a linked list of 
 * ControlPages. These control pages are fulled with
 * Slots - each slot container a pointer to a bitmap 
 * and other metadata
 */

import lib.util.result;
import lib.util.bitmap;
import lib.util.console;

import common.memory.physical;

version(X86_64) import arch.amd64.memory;

private static immutable BlockSizes = [2, 4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048, 4096];

// Determines which list a block allocation should fit in
private size_t getBlockIndex(size_t allocSize) {
	for (size_t i = 0; i < BlockSizes.length; i++) 
		if (BlockSizes[i] >= allocSize)
			return i;
	
	assert(0); 	// Unreachable - size is checked by newObj()
}

private struct Slot {
	void*   page;   // Page that is under this Slot's control
	BitMap  bitMap; // Bitmap that manages the page
	size_t  gran;   // Size of each allocation
}

// Must be exactly one page in size
private struct ControlPage {
	ControlPage* next;
	Slot[(PageSize - size_t.sizeof) / Slot.sizeof] slots;
}

private struct BitMapPage {
	ubyte* top; // Latest bitmap created
}

//////////////////////////////
//         Instance         //
//////////////////////////////

private __gshared ControlPage* controlPages;
private __gshared BitMapPage* topBitMapPage;

void initBitSlabAlloc() {
	// Allocate 1 page to each list 
	controlPages  = cast(ControlPage*) newBlock().unwrapResult();
	topBitMapPage = cast(BitMapPage*)  newBlock().unwrapResult();

	controlPages.next  = null;
}

void* newBitSlabAlloc(size_t size, bool zero) {
	size_t index = getBlockIndex(size);

	// Find or create a slot
	auto curControlPage = controlPages;
	while (true) {
		for (size_t i = 0; i < curControlPage.slots.length; i++) {
			auto slot = &curControlPage.slots[i];

			// Slot with correct granularity and space found
			if (!slot.bitMap.full && slot.gran == BlockSizes[index]) {
				auto bit = slot.bitMap.nextFree;
				slot.bitMap.setBit(bit);

				ubyte* alloc = cast(ubyte*) (slot.page + slot.gran * bit);

				if (zero) 
					alloc[0..BlockSizes[index]] = 0;

				// Update nextFree and return
				for (size_t j = slot.bitMap.nextFree; j < slot.bitMap.size; j++) {
					if (!slot.bitMap.testBit(j)) {
						slot.bitMap.nextFree = j;
						return cast(void*) alloc;
					}
				}	
				// No more free space in bitmap
				slot.bitMap.full = true;
				return cast(void*) alloc;
			}

			/* Slots full up contigously, therefore an empty slot means
			 * that we have reached the end of the list but have space
			 */
			if (slot.page == null) {
				void* page;
				auto result = newBlock(1, false);
				if (result.isOkay)
					page = result.unwrapResult();
				else
					return null;
				
				auto count = PageSize / BlockSizes[index];
				
				// Find or create space for a new bitmap
				ubyte* map;
				if (cast(size_t) &topBitMapPage.top < PageSize) {
					map = topBitMapPage.top;
				} else {
					auto result2 = newBlock(1, false);		
					if (result.isOkay)
						topBitMapPage = cast(BitMapPage*) result2.unwrapResult();
					else
						return null;
				
					map = cast(ubyte*) (topBitMapPage + BitMapPage.sizeof);
				}

				// Create slot
				*slot = Slot(page, BitMap(map, count), BlockSizes[index]);
				topBitMapPage.top = map + count / 8;

				// Allocate
				slot.bitMap.setBit(0);
				slot.bitMap.nextFree++;
				return slot.page;
			}
		}
		
		if (curControlPage.next != null) {
			curControlPage = curControlPage.next;
			continue;
		}

		// Allocate a new control page
		auto result = newBlock(1, false);
		if (result.isOkay)
			curControlPage.next = cast(ControlPage*) result.unwrapResult();
		else
			return null;
		curControlPage = curControlPage.next;
	}
}

bool delBitSlabAlloc(void* where) {
	auto curControlPage = controlPages;

	while (true) {
		for (size_t i = 0; i < controlPages.slots.length; i++) {
			auto slot = &curControlPage.slots[i];

			// Object is in this slot
			if (slot.page != null && where >= slot.page && where < slot.page + PageSize) {
				auto bit = (cast(size_t) where % PageSize) / slot.gran;

				slot.bitMap.unsetBit(bit);
				slot.bitMap.nextFree = bit;

				if (slot.bitMap.full)
					slot.bitMap.full = false;

				return true;
			}
		}
		
		if (curControlPage.next == null) 
			return false;

		curControlPage = curControlPage.next;
	}
}