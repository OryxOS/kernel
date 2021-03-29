import lib.stivale;
import lib.std.stdio;
import lib.std.result;

import io.framebuffer;

enum GetIntError {
	BoolWasFalse,
}

alias GetIntResult = Result!(int, GetIntError);

GetIntResult getInt(bool good, int val) {
	if (good) {
		return GetIntResult(val);
	} else {
		return GetIntResult(GetIntError.BoolWasFalse);
	}
}

extern (C) void main(StivaleInfo* stivale) {
	initFrameBuffer(stivale);
	initConsole();

	writefln("OryxOS Booted");
	stivale.displayBootInfo();

	version (X86_64) {
		import arch.amd64.gdt             : initGdt;
		import arch.amd64.memory.physical : initPmm;
		writefln("\nAmd64 Init:");

		initGdt();
		initPmm(stivale);
	}

	int good;
	GetIntResult result = getInt(true, 32);

	if (result.isOkay) {
		good = result.unwrap();
	} else {
		assert(0, "Result not good");
	}

	asm { hlt; }
}