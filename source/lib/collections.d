module lib.collections;

// Various different heap-allocated collections

import au.types;

import memory.allocator;

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
    ///     init_size  = initial number of elements
    ///     init_value = value to set al initial elements to
    this(usize init_size, T init_value) {
		this.storage = new_obj!(Node)();

		auto node = this.storage;
		foreach (_; 1..init_size) {
			node.next = new_obj!(Node)();
			node.item = init_value;

			node = node.next;
		}

		this.length = init_size;
	}

	usize get_length() {
		return this.length;
	}

    /// Deletes a LinkedList (Removes all elements)
    void remove_all() {
		foreach (i; 0..this.length - 1)
			this.remove(0);
	}

    // Index operator overload. eg: list[12]
    ref T opIndex(usize index) {
		assert (index < this.length); // Overflow Prevention

		// Loop though all nodes until index node is found
		auto node = this.storage;
		foreach ( _; 0..index)
			node = node.next;

		return node.item;
	}

    /// Add an element to the end of the list
    void append(T value) {
		// First append handled differently
		if (this.storage == null) {
			this.storage = new_obj!(Node)();
			
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

		current.next = new_obj!(Node)();

		current.next.item = value;
		current.next.next = null;

		this.length++;
	}

    /// Remove an element from its index
    void remove(usize index) {
		assert (index < this.length); // Overflow Prevention

		this.length--;

		if (index == 0) {
			auto new_first = this.storage.next;

			del_obj!(Node)(this.storage);

			this.storage = new_first;
			return;
		}

		// Get node before & after index
		auto pre_node = this.storage;
		foreach(_; 0..index - 1)
			pre_node = pre_node.next;
			
		auto next_node = pre_node.next.next;

		del_obj!(Node)(pre_node.next);

		pre_node.next = next_node;
	}
}