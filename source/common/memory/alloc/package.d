module common.memory.alloc;

import lib.std.stdio;

import common.memory.alloc.bitslab;

void initAlloc() {
	writefln("\nAllocator Init:");

	initBitSlabAlloc();
	writefln("BitSlab allocator initialized successfully");
}