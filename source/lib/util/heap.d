module lib.util.heap;

/* OryxOS Heap Allocation Library
 * This is library of useful heap allocation
 * functions and structures
 */

import lib.util.types;
import lib.util.console;

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
		return cast(T*) newBitSlabAlloc(T.sizeof, true);
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
	return delBitSlabAlloc(cast(void*) obj);
}

/// Allocates space for a contiguous array of objects on the heap
/// Params:
/// 	T    = type to allocate space for
/// 	size = number of T's to allocate
/// Returns:
/// 	null = allocation failed (NEM)
/// 	addr = Address of the allocation
T* newArr(T)(usize size) {
	if (T.sizeof * size <= PageSize)
		return cast(T*) newBitSlabAlloc(T.sizeof * size, true);
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
	return delBitSlabAlloc(cast(void*) array);
}

////////////////////////
//    Linked Lists    //
////////////////////////


struct LinkedList(T) {
    private struct Node {
        Node* next;
        T     item;
    }

    private Node*  storage;
    private usize  length;

    /// Creates a new LinkedList
    /// Params:
    ///     initSize  = initial number of elements
    ///     initValue = value to set al initial elements to
    this(usize initSize, T initValue) {
		this.storage = newObj!(Node)();

		auto curNode = this.storage;
		foreach (_; 1..initSize) {
			curNode.next = newObj!(Node)();
			curNode.item = initValue;

			curNode = curNode.next;
		}

		this.length = initSize;
	}

	usize getLength() {
		return this.length;
	}

    /// Deletes a LinkedList (Removes all elements)
    void removeAll() {
		foreach (i; 0..this.length - 1)
			this.remove(0);
	}

    // Index operator overload. eg: list[12]
    ref T opIndex(usize index) {
		assert (index < this.length); // Overflow Prevention

		// Loop though all nodes until index node is found
		auto curNode = this.storage;
		foreach ( _; 0..index)
			curNode = curNode.next;

		return curNode.item;
	}

    /// Add an element to the end of the list
    void append(T value) {
		// Find append handled differently
		if (this.storage == null) {
			this.storage = newObj!(Node)();
			
			this.storage.next = null;
			this.storage.item = value;

			this.length++;
			return;
		}

		// Standard append

		// Get the end of the list
		auto current = this.storage;
		while (current.next != null)
			current = current.next;

		current.next = newObj!(Node)();

		current.next.item = value;
		current.next.next = null;

		this.length++;
	}

    /// Remove a value from the list
    void remove(usize index) {
		assert (index < this.length); // Overflow Prevention

		this.length--;

		if (index == 0) {
			auto newFirst = this.storage.next;

			delObj!(Node)(this.storage);

			this.storage = newFirst;
			return;
		}

		// Get node before & after index
		auto preNode = this.storage;
		foreach(_; 0..index - 1)
			preNode = preNode.next;
			
		auto postNode = preNode.next.next;

		delObj!(Node)(preNode.next);

		preNode.next = postNode;
	}
}