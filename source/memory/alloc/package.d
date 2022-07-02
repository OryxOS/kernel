module memory.alloc;

import io.console;

import memory.alloc.bitslab;

void initAlloc() {
	writefln("\nAllocator Init:");

	initBitSlabAlloc();
	log(1, "BitSlab allocator initialized successfully");
}