module lib.std.heap;

/* OryxOS Heap Allocation Library
 * This is library of useful heap allocation
 * functions and structures
 */

import lib.std.stdio;

import common.memory.alloc.bitslab;
import arch.amd64.memory;

/// Allocates space for an object on the heap
/// Params:
/// 	T = type to allocate space for
/// Returns:
/// 	null = allocation failed (NEM)
/// 	addr = Address of the allocation
T* newObj(T)() {
	if (T.sizeof <= PageSize)
		return cast(T*)(newBitSlabAlloc(T.sizeof, true));
	else
		panic("TODO: allocations > than PageSize");

	assert(0);  // Unreachable
}

/// Deletes an object from the heap
/// Params:
/// 	obj = pointer to object to be deleted
/// Returns:
/// 	true  = deletion was a success
/// 	false = deletion failed (Object not on heap)
bool delObj(T)(T* obj) {
	return delBitSlabAlloc(cast(void*)(obj));
}

/// Allocates space for a contiguous array of objects on the heap
/// Params:
/// 	T    = type to allocate space for
/// 	size = number of T's to allocate
/// Returns:
/// 	null = allocation failed (NEM)
/// 	addr = Address of the allocation
T* newArr(T)(size_t size) {
	if (T.sizeof * size <= PageSize)
		return cast(T*)(newBitSlabAlloc(T.sizeof * size, true));
	else
		panic("TODO: allocations > than PageSize");

	assert(0); // Unreachable
}


/// Deletes an array of objects from the heap
/// Params:
/// 	array = pointer to array to be deleted
/// Returns:
/// 	true  = deletion was a success
/// 	false = deletion failed (Array not on heap)
bool delArr(T)(T* array)  {
	return delBitSlabAlloc(cast(void*)(array));
}

////////////////////////
//    Linked Lists    //
////////////////////////

struct LinkedList(T) {
	// List Node
	private struct Node {
		Node* next = null;
		T     item;
	}

	private Node* list; // Actual list
	size_t capacity;    // Number of elements in the list

	this(size_t initSize, T initValue) {
		this.list = newObj!(Node)();

		auto curNode = this.list;
		foreach (_; 1..initSize) {
			curNode.next = newObj!(Node)();
			curNode.item = initValue;

			curNode = curNode.next;
		}

		this.capacity = initSize;
	}
	/*
	~this() {
		foreach (i; 0..this.capacity - 1)
			this.remove(i);
	}
	*/

	ref T opIndex(size_t index) {
		assert (index < this.capacity); // Overflow Prevention

		// Loop though all nodes
		auto curNode = this.list;
		foreach ( _; 0..index)
			curNode = curNode.next;

		return curNode.item;
	}

	auto opOpAssign(string op, T)(T value) {
		writefln("Called");
		switch(op) {
		case "~":
			// Loop though all nodes to find last
			auto curNode = this.list;
			foreach ( _; 0..this.capacity - 1)
				curNode = curNode.next;

			//  Setup new node
			auto append  = newObj!(Node)();
			append.item  = value;
			curNode.next = append;

			this.capacity++;
			break;

		default:
			panic("Linked Lists do not support operand \"%s\"", op);
			break;
		}
		return this;
	}

	void remove(size_t index) {
		writefln("Called with index: %d", index);
		assert (index < this.capacity); // Overflow Prevention

		if (index == 0) {
			if (this.list.next != null) { 
				Node* newFirst = this.list.next;	// Save Node at index 1
				delObj!(Node)(this.list);			// Destroy index 0
				this.list = newFirst;				// Set index 0 to index 1
			} else {
				delObj!(Node)(this.list);			// Destroy index 0
				this.list = null;					// Set index 0 to null
			}			
		} else if (index == this.capacity - 1) {
			// Get node before index
			auto curNode = this.list;
			foreach(_; 0..index - 1)
				curNode = curNode.next;
			
			delObj!(Node)(curNode.next); // Delete Node
			curNode.next = null;         // Set end of node
		} else {
			// Get node before & after index
			auto preNode = this.list;
			foreach (_; 0..index - 1)
				preNode = preNode.next;
			auto postNode = preNode.next.next;

			delObj!(Node)(preNode.next); // Delete index node
			preNode.next = postNode;     // Stitch list back together
		}
		
		this.capacity--;
	}
}