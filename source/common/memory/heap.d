module common.memory.heap;

/* OryxOS kernel allocator
 * This allocator has two allocation mechanisms.
 * There is a bitmap allocator for small allocations
 * and a slab allocator for large ones.
 */

import lib.std.math;
import lib.std.stdio;
import lib.std.result;
import lib.std.bitmap;

import common.memory;
import common.memory.physical;

version (X86_64) import arch.amd64.memory;

private struct Slab {
	Slab*        next;  // Pointer to next slab
	size_t       gran;  // Size of each allocation
	VirtAddress  start; // Start of slab;
	BitMap       map;

	this(size_t size) {
		auto page = &this;
		
		this.next = null;
		this.gran = size;

		auto entryCount = (PageSize - Slab.sizeof) / gran;
		auto bitMapSize = divRoundUp(entryCount,  8);

		// Bitmap will take up some space
		entryCount -= divRoundUp(bitMapSize, size);

		this.map   = BitMap(cast(ubyte*)(page + Slab.sizeof), bitMapSize * 8);
		this.start = page + Slab.sizeof + bitMapSize;
	}

	SlabResult alloc(size_t size) {
		if (this.map.full == true)
			return SlabResult(SlabError.SlabFull);

		if (this.gran != size)
			return SlabResult(SlabError.WrongGranularity);

		size_t i;
		for (i = this.map.nextFree; i < this.map.size; i++) {
			if (!this.map.testBit(i)) {
				this.map.nextFree = i;
				return SlabResult(start + this.map.nextFree * gran);
			}			
		}

		if (i == this.map.size) {
			this.map.full = true;
			return SlabResult(start + this.map.nextFree * gran);
		}

		assert (0);
	}
}

private enum SlabError {
	WrongGranularity,
	SlabFull,
}
private alias SlabResult = Result!(VirtAddress, SlabError);

//////////////////////////////
//         Instance         //
//////////////////////////////

private __gshared Slab* slabs;

void initHeap() {
	writefln("\nInitializing kernel heap:");
	auto slab = cast(Slab*)(newBlock(1).unwrapResult);

	*slab = Slab(1024);

	SlabResult res1 = slab.alloc(1024);
	SlabResult res2 = slab.alloc(1024);
	SlabResult res3 = slab.alloc(1024);
	SlabResult res4 = slab.alloc(1024);

	if (res1.isOkay) {
		writefln("Good: %h", cast(ulong)(res1.unwrapResult()));
	} else {
		writefln("Fail: %d", res1.unwrapError());
	}

	if (res2.isOkay) {
		writefln("Good: %h", cast(ulong)(res2.unwrapResult()));
	} else {
		writefln("Fail: %d", res2.unwrapError());
	}

	if (res3.isOkay) {
		writefln("Good: %h", cast(ulong)(res3.unwrapResult()));
	} else {
		writefln("Fail: %d", res3.unwrapError());
	}

	if (res4.isOkay) {
		writefln("Good: %h", cast(ulong)(res4.unwrapResult()));
	} else {
		writefln("Fail: %d", res4.unwrapError());
	}
}

/// Allocates new memory for `count` number of objects
/// Params:
/// 	count = number of objects to allocate
/// Returns:
/// 	Pointer to the memory allocated on success
/// 	Null on failure
T* newObject(T)(size_t count = 1) {
	immutable auto size = T.sizeof;

}

T* delObject(T)();
