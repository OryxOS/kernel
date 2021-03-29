deprecated("Compiler intrinsics. Do not invoke") module lib.std.runtime.panic;

import lib.std.string;
import lib.std.stdio;

// ``assert`` function
extern (C) void __assert(const char* exp, const char* file, uint line) {
	writefln("Assert: %s", fromCString(exp));
	writefln("Where:  %s:%d", fromCString(file), line);
	
	// Hang the kernel
	asm {
		cli;
		hlt;
	}
}