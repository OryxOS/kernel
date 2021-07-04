module common.memory.alloc;

import lib.std.stdio;
import lib.std.result;

import common.memory.alloc.bitslab;
import arch.amd64.memory;

void initAlloc() {
	writefln("\nAllocator Init:");

	initBitSlabAlloc();
}

/// Allocates memory for a supplied obj
/// Params:
/// 	T     = Type to allocate
///     count = Number of Ts to allocate contigous space for
/// Returns:
/// 	null = Not enough memory remaining for allocation
T* newObj(T)(size_t count = 1) {
	if (T.sizeof * count <= PageSize)
		return cast(T*)(newBitSlabAlloc((T.sizeof * count), true));
	else 
		panic("TODO: allocations greater than 4096 bytes");

	assert(0);
}

/// Attempts to free an allocation
/// Params:
/// 	obj = pointer to the object to delete
/// Returns:
/// 	true  = deletion was successful
/// 	false = address in not in heap
bool delObj(T)(T* obj) {
	return delBitSlabAlloc(cast(void*)(obj));
}