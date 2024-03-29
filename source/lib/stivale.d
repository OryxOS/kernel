module lib.stivale;

import lib.util.types;
import lib.util.string;
import lib.util.console;

import common.memory.map;

// Tags
enum FrameBufferID = 0x506461d2950408fa;
enum MemMapID      = 0x2187f79e8612de07;
enum XsdtPointerID = 0x9e1786930a375e78;	
enum ModuleID      = 0x4b6fe466aade04ce;

// All tags have this at their start
struct StivaleTag {
	align (1):
	ulong ident;
	StivaleTag* next;
}

struct StivaleInfo {
	align (1):
	char[64] bootloaderBrand;
	char[64] bootloaderVersion;

	StivaleTag* tags;

	void* getTag(ulong ident) {
		StivaleTag* curTag = this.tags;

		while(1) {
			// Tag is present
			if (curTag.ident == ident) {
				return cast(void*) curTag;
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


struct FrameBufferTag {
	align (1):
	StivaleTag tag;

	void* address;

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

struct MemMapTag {
	align (1):
	StivaleTag tag;
	ulong      entryCount;
	Region     entries;	   // Varlength arrays don't exist in D
}

struct XsdtPointerTag {
	align (1):
	StivaleTag tag;
	usize      pointer;
}

struct ModuleTag {
	align (1):
	StivaleTag tag;
	usize      count;
	Module     modules;

	/// Attempts to find a module with a string matching `str`
	Module* getModule(string str) {
		foreach (i; 0..this.count) {
			auto mod = cast (Module*) (cast (usize) &this.modules + i * Module.sizeof);

			// Check if strings match
			if (fromCString(cast(char*) &mod.str) == str)
				return mod;
		}

		// No module could be found
		return null;
	}
}

struct Module {
	align(1):
	usize     start;
	usize     end;
	char[512] str;
}