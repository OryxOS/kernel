module common.memory.alloc.block;

/* OryxOS Fixed Block Allocator
 * Fixed Block allocators are designed for speed over
 * memory usage. They work by having a set of linked lists,
 * each of a different, set allocation size.
 */

import lib.std.stdio;
import lib.std.result;

import common.memory;
import common.memory.physical;

version (X86_64) import arch.amd64.memory;

private static immutable BlockSizes = [2, 4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048];

private struct Node {
	Node* next;
	bool  free;
}

// Determines which list a block allocation should fit in
private size_t getBlockIndex(size_t allocSize) {
	for (size_t i = 0; i < BlockSizes.length; i++) 
		if (BlockSizes[i] >= allocSize)
			return i;
	
	assert(0); 	// Unreachable
}

//////////////////////////////
//         Instance         //
//////////////////////////////

private __gshared Node*[BlockSizes.length] lists;

void initBlockAlloc() {
	// Allocate initial space for each list and link each node
	for (size_t i = 0; i < BlockSizes.length; i++) {
		auto region  = newBlock().unwrapResult;
		auto entries = PageSize / (Node.sizeof + BlockSizes[i]);
		
		lists[i] = cast(Node*)(region);

		auto curNode = lists[i];

		for (size_t j = 1; j < entries - 1; j++) {
			curNode.free = true;
			curNode.next = cast(Node*)(region + (Node.sizeof + BlockSizes[i]) * j);
			curNode = curNode.next;
		}

		curNode.next = null; // Last node points to nothing
	}
	
}

void* newBlockAlloc(size_t size, bool zero = true) {
	size_t index = getBlockIndex(size);	
	auto curNode = lists[index];

	// Find an available block
	while (true) {
		if (curNode.free) {
			curNode.free = false;
			
			auto ret = cast(ubyte*)(curNode + Node.sizeof);

			if (zero)
				ret[0..BlockSizes[index]] = 0;

			return ret;
		}

		if (curNode.next != null) {
			curNode = curNode.next;
		} else {
			// Add a new page to the list
			auto region  = newBlock().unwrapResult;
			auto entries = PageSize / (Node.sizeof + BlockSizes[index]);

			curNode.next = cast(Node*)(region);
			curNode.next.free = false;

			auto newNode = curNode.next;
			for (size_t j = 1; j < entries - 1; j++) {
				newNode.free = true;
				newNode.next = cast(Node*)(region + (Node.sizeof + BlockSizes[index]) * j);
				newNode = curNode.next;
			}

			newNode.next = null; // Last node points to nothing 

			return cast(void*)(curNode.next + Node.sizeof);
		}
	}
}

bool delBlockAlloc(void* where, size_t size) {
	size_t index = getBlockIndex(size);
	auto curNode = lists[index];

	while (true) {
		if(cast(void*)(curNode + Node.sizeof) == where) {
			curNode.free = true;
			return true;
		}

		if (curNode.next != null)
			curNode = curNode.next;
		else
			return false;
	}
}