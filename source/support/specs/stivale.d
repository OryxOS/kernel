module support.specs.stivale;

// Library for working with the Stivale2 boot protocol

// Tags
immutable FRAMEBUFFER_ID = 0x506461d2950408fa;

align(1) struct StivaleInfo {
	char[64] bootloaderBrand;
	char[64] bootloaderVersion;

	StivaleTag* tags;

	void* getTag(ulong ident) {
		StivaleTag* curTag = this.tags;

		while(1) {
			if (curTag.ident = ident) {
				return cast(void*)(curTag);
			}

			if (curTag.next = null) {
				return null;
			}

			curTag = curTag.next;
		}
	}
}

align(1) struct StivaleTag {
	ulong ident;
	StivaleTag* next;
}

align(1) struct FrameBufferTag {
	StivaleTag tag;

	ulong address;

	ushort width;
	ushort height;
	ushort pitch;
	ushort bpp;

	ubyte memoryModel;
	ubyte rMaskSize;
	ubyte rMaskShift;
	ubyte gMaskSize;
	ubyte gMaskShift;
	ubyte bMaskSize;
	ubyte bMaskShift;
}