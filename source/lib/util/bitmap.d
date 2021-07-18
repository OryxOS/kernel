module lib.util.bitmap;

import lib.util.types;

// Module for working with bitmaps, used in both our heap and physical allocator

/// Standard bitmap structure
struct BitMap {
	ubyte* map;     // The actual bitmap
	usize size;     // Size (bits) of the bitmap
	usize nextFree; // Next available bit
	bool   full;

	this(ubyte* map, usize size) {
		this.map = map;
		this.size = size;
	}

    /// Checks if a bit is set
	bool testBit(usize bit) {
		assert(bit <= this.size);
		return !!(map[bit / 8] & (1 << (bit % 8)));
	}
	
	/// Sets a bit
	void setBit(usize bit) {
		assert(bit <= this.size);
		this.map[bit / 8] |= (1 << (bit % 8));
	}

	/// Unsets a bit
	void unsetBit(usize bit) {
		assert(bit <= this.size);
		this.map[bit / 8] &= ~(1 << (bit % 8));
	}
}
