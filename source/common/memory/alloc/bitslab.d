module common.memory.alloc.bitslab;

/* OryxOS <TO BE NAMED> Allocator
 * The <TO BE NAMED> allocator consists of 2 linked lists
 * 
 * List 1: A linked list of pages. Each page is an array
 *         of structs. There structs contain a pointer 
 *         to a bitmap and some metadata
 *
 * List 2: A linked list of pages. Each is fulled with
 *         bitmaps, each of a different size and
 *         granularity. Each bitmap must account for 1
 *         page
 */

import lib.std.stdio;
import lib.std.result;
import lib.std.bitmap;

import common.memory.physical;

version(X86_64) import arch.amd64.memory;

private static immutable BlockSizes = [2, 4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048, 4096];

// Determines which list a block allocation should fit in
private size_t getBlockIndex(size_t allocSize) {
	for (size_t i = 0; i < BlockSizes.length; i++) 
		if (BlockSizes[i] >= allocSize)
			return i;
	
	assert(0); 	// Unreachable
}

private struct Slot {
	void*   page;   // Page that is under this Slot's control
	BitMap  bitMap; // Bitmap that manages the page
	size_t  gran;   // Size of each allocation
}

private struct ControlPage {
	ControlPage* next;
	Slot[(PageSize - size_t.sizeof) / Slot.sizeof] slots;
}

private struct BitMapPage {
	ubyte* top; // Highest bitmap in page
}

//////////////////////////////
//         Instance         //
//////////////////////////////

private __gshared ControlPage* controlPages;
private __gshared BitMapPage* topBitMapPage;

void initBitSlabAlloc() {
	// Allocate 1 page to each list 
	controlPages  = cast(ControlPage*)(newBlock().unwrapResult());
	topBitMapPage = cast(BitMapPage*)(newBlock().unwrapResult());

	controlPages.next  = null;
}

void* newBitSlabAlloc(size_t size) {
	size_t index = getBlockIndex(size);

	// Find or create a slot
	auto curControlPage = controlPages;
	while (true) {
		for (size_t i = 0; i< controlPages.slots.length; i++) {
			auto slot = &curControlPage.slots[i];

			// Slot with correct granularity and space found
			if (!slot.bitMap.full && slot.gran == BlockSizes[index]) {
				auto bit = slot.bitMap.nextFree;
				slot.bitMap.setBit(bit);

				// Update nextFree and return
				size_t j;
				for (j = 0; j < slot.bitMap.size; j++) {
					if (!slot.bitMap.testBit(j)) {
						slot.bitMap.nextFree = j;

						return slot.page + slot.gran * bit;
					}
				}
				// No more free space in bitmap
				if (j == slot.bitMap.size) {
					slot.bitMap.full = true;
					return slot.page + slot.gran * bit;
				}
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
				if (cast(size_t)(&topBitMapPage.top) < PageSize) {
					map = topBitMapPage.top;
				} else {
					auto result2 = newBlock(1, false);		
					if (result.isOkay)
						topBitMapPage = cast(BitMapPage*)(result2.unwrapResult());
					else
						return null;
				
					map = cast(ubyte*)(topBitMapPage + BitMapPage.sizeof);
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

		// Find or allocate a new control page
		if (curControlPage.next != null) {
			curControlPage = curControlPage.next;
		} else {
			auto result = newBlock(1, false);
			if (result.isOkay)
				curControlPage.next = cast(ControlPage*)(result.unwrapResult());
			else
				return null;

			curControlPage = curControlPage.next;
		}
	}
}

bool delBitSlabAlloc(void* where, size_t count) {
	auto curControlPage = controlPages;
	while (true) {
		for (size_t i = 0; i< controlPages.slots.length; i++) {
			auto slot = &curControlPage.slots[i];

			// Allocation under slot's control
			if (where > slot.page && where < slot.page + 4096) {
				
			}	
		}
		
		if (curControlPage.next != null) 
			curControlPage = curControlPage.next;
		else
			return false;
	}
}