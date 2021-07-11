module common.memory.alloc;

import lib.util.console;

import common.memory.alloc.bitslab;

void initAlloc() {
	writefln("\nAllocator Init:");

	initBitSlabAlloc();
	log(1, "BitSlab allocator initialized successfully");
}