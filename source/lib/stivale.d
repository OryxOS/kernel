module lib.stivale;

import lib.std.stdio;

import common.memory.map;

// Tags
enum FrameBufferID = 0x506461d2950408fa;
enum MemMapID      = 0x2187f79e8612de07;

// All tags have this at their start
align (1) struct StivaleTag {
	ulong ident;
	StivaleTag* next;
}

align (1) struct StivaleInfo {
	char[64] bootloaderBrand;
	char[64] bootloaderVersion;

	StivaleTag* tags;

	void* getTag(ulong ident) {
		StivaleTag* curTag = this.tags;

		while(1) {
			// Tag is present
			if (curTag.ident == ident) {
				return cast(void*)(curTag);
			}

			// Tag isn't present
			if (curTag.next == null) {
				return null;
			}

			curTag = curTag.next;
		}
	}

	void displayBootInfo() {
		putChr('\n');
		log(0, "Boot Info:");
		
		writef("\tBootloader brand: ");
		foreach(c; bootloaderBrand) {
			if (c != '\0') {
				putChr(c);
			}
		}
		putChr('\n');

		writef("\tBootloader version: ");
		foreach(c; bootloaderVersion) {
			if (c != '\0') {
				putChr(c);
			}
		}
		putChr('\n');
	}
}


align (1) struct FrameBufferTag {
	StivaleTag tag;

	void*  address;

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


align (1) struct MemMapTag {
	StivaleTag tag;
	ulong      entryCount;
	Region     entries;	   // Varlength arrays don't exist in D
}