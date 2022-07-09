module memory.allocator;

/* OryxOS BitSlab (Bitmap + Slab) Allocator
 * The BitSlab allocator consists of a linked list of 
 * ctrl_pages. These control pages are fulled with
 * Slots - each slot container a pointer to a bitmap 
 * and other metadata
 */

import au.types;
import au.result;
import au.bitmap;

import io.console;

version(X86_64) import arch.amd64.memory;

private static immutable BlockSizes = [2, 4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048, 4096];

// Determines which list a block allocation should fit in
private usize get_block_index(usize size) {
	for (usize i = 0; i < BlockSizes.length; i++) 
		if (BlockSizes[i] >= size)
			return i;
	
	assert(0); // Unreachable - size is checked by new_obj()
}

private struct Slot {
	void* page; // Page that is under this Slot's control
	BitMap bitmap;    // Bitmap that manages the page
	usize gran;       // Size of each allocation
}

// Must be exactly one page in size
private struct ControlPage {
	ControlPage* next;
	Slot[(PageSize - usize.sizeof) / Slot.sizeof] slots;
}

private struct BitMapPage {
	ubyte* top; // Latest bitmap created
}

//////////////////////////////
//         Instance         //
//////////////////////////////

private __gshared ControlPage* ctrl_pages;
private __gshared BitMapPage* top_bitmap_page;

void init_alloc() {
	writefln("\nAllocator Init:");

	init_bitslab_alloc();
	log(1, "BitSlab allocator initialized successfully");
}

private void init_bitslab_alloc() {
	// Allocate 1 page to each list 
	ctrl_pages      = cast(ControlPage*) new_page().unwrap_result();
	top_bitmap_page = cast(BitMapPage*)  new_page().unwrap_result();

	ctrl_pages.next = null;
}

private void* new_bitslab_alloc(usize size, bool zero) {
	usize index = get_block_index(size);

	// Find or create a slot
	auto ctrl_page = ctrl_pages;
	while (true) {
		for (usize i = 0; i < ctrl_page.slots.length; i++) {
			auto slot = &ctrl_page.slots[i];

			// Slot with correct granularity and space found
			if (!slot.bitmap.full && slot.gran == BlockSizes[index]) {
				auto bit = slot.bitmap.next_free;
				slot.bitmap.set_bit(bit);

				ubyte* alloc = cast(ubyte*) (slot.page + slot.gran * bit);

				if (zero) 
					alloc[0..BlockSizes[index]] = 0;

				// Update next_free and return
				for (usize j = slot.bitmap.next_free; j < slot.bitmap.size; j++) {
					if (!slot.bitmap.test_bit(j)) {
						slot.bitmap.next_free = j;
						return cast(void*) alloc;
					}
				}	
				// No more free space in bitmap
				slot.bitmap.full = true;
				return cast(void*) alloc;
			}

			/* Slots full up contigously, therefore an empty slot means
			 * that we have reached the end of the list but have space
			 */
			if (slot.page == null) {
				void* page;
				auto result = new_page(1, false);
				if (result.is_good)
					page = result.unwrap_result();
				else
					return null;
				
				auto count = PageSize / BlockSizes[index];
				
				// Find or create space for a new bitmap
				ubyte* map;
				if (cast(usize) &top_bitmap_page.top < PageSize) {
					map = top_bitmap_page.top;
				} else {
					auto result2 = new_page(1, false);		
					if (result.is_good)
						top_bitmap_page = cast(BitMapPage*) result2.unwrap_result();
					else
						return null;
				
					map = cast(ubyte*) (top_bitmap_page + BitMapPage.sizeof);
				}

				// Create slot
				*slot = Slot(page, BitMap(map, count), BlockSizes[index]);
				top_bitmap_page.top = map + count / 8;

				// Allocate
				slot.bitmap.set_bit(0);
				slot.bitmap.next_free++;
				return slot.page;
			}
		}
		
		if (ctrl_page.next != null) {
			ctrl_page = ctrl_page.next;
			continue;
		}

		// Allocate a new control page
		auto result = new_page(1, false);
		if (result.is_good)
			ctrl_page.next = cast(ControlPage*) result.unwrap_result();
		else
			return null;
		ctrl_page = ctrl_page.next;
	}
}

private bool del_bitslab_alloc(void* where) {
	auto ctrl_page = ctrl_pages;

	while (true) {
		for (usize i = 0; i < ctrl_pages.slots.length; i++) {
			auto slot = &ctrl_page.slots[i];

			// Object is in this slot
			if (slot.page != null && where >= slot.page && where < slot.page + PageSize) {
				auto bit = (cast(usize) where % PageSize) / slot.gran;

				slot.bitmap.unset_bit(bit);
				slot.bitmap.next_free = bit;

				if (slot.bitmap.full)
					slot.bitmap.full = false;

				return true;
			}
		}
		
		if (ctrl_page.next == null) 
			return false;

		ctrl_page = ctrl_page.next;
	}
}

//////////////////////////////
//         Templates        //
//////////////////////////////

/// Allocates space for an object on the heap
/// Params:
/// 	T = type to allocate space for
/// Returns:
/// 	null = allocation failed (NEM)
/// 	addr = Address of the allocation
T* new_obj(T)() {
	if (T.sizeof <= PageSize)
		return cast(T*) new_bitslab_alloc(T.sizeof, true);
	else
		assert(0, "TODO: allocations > than PageSize");

	assert(0);  // Unreachable
}



/// Deletes an object from the heap
/// Params:
/// 	obj = pointer to object to be deleted
/// Returns:
/// 	true  = deletion was a success
/// 	false = deletion failed (Object not on heap)
bool del_obj(T)(T* obj) {
	return del_bitslab_alloc(cast(void*) obj);
}

/// Allocates space for a contiguous array of objects on the heap
/// Params:
/// 	T    = type to allocate space for
/// 	size = number of T's to allocate
/// Returns:
/// 	null = allocation failed (NEM)
/// 	addr = Address of the allocation
T* new_arr(T)(usize size) {
	if (T.sizeof * size <= PageSize)
		return cast(T*) new_bitslab_alloc(T.sizeof * size, true);
	else
		assert(0, "TODO: allocations > than PageSize");

	assert(0); // Unreachable
}


/// Deletes an array of objects from the heap
/// Params:
/// 	array = pointer to array to be deleted
/// Returns:
/// 	true  = deletion was a success
/// 	false = deletion failed (Array not on heap)
bool del_arr(T)(T* array)  {
	return del_bitslab_alloc(cast(void*) array);
}