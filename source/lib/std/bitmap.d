module lib.std.bitmap;

/* OryxOS heap allocator
 */

/// Standard bitmap structure
align struct BitMap {
	ubyte* map;       // The actual bitmap
	size_t size;      // Size (bits) of the bitmap
    size_t nextFree;  // Next available bit
	bool   full;

	this(ubyte* map, size_t size) {
		this.map = map;
		this.size = size;
	}

    /// Checks if a bit is set
    /// Returns:
    ///     true if set
    ///     false if unset
	bool testBit(size_t bit) {
		assert(bit <= this.size);
		return !!(map[bit / 8] & (1 << (bit % 8)));
	}
	
    /// Sets a bit
	void setBit(size_t bit) {
		assert(bit <= this.size);
		this.map[bit / 8] |= (1 << (bit % 8));
	}

    /// Unsets a bit
	void unsetBit(size_t bit) {
		assert(bit <= this.size);
		this.map[bit / 8] &= ~(1 << (bit % 8));
	}
}
