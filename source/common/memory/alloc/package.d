module common.memory.alloc;

import lib.std.stdio;
import lib.std.result;

import common.memory.alloc.block;

void initAlloc() {
	writefln("\nAllocator Init:");
	initBlockAlloc();
	log(1, "Fixed Block Allocator initialized");
}

/// Attemps to allocate a block of a given size
/// Params:
/// 	T = Type to allocate
/// Returns:
/// 	null = Not enough memory remaining for allocation
/// 	       or alloc size too great
T* newObj(T)() {
	return cast(T*)(newBlockAlloc(T.sizeof));
}

/// Attempts to free an allocation
/// Params:
/// 	obj = pointer to the object to delete
/// Returns:
/// 	true  = deletion was successful
/// 	false = address in not in heap
bool delObj(T)(T* obj) {
	return delBlockAlloc(cast(void*)(obj), T.sizeof);
}