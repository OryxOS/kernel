deprecated("Compiler intrinsics. Do not invoke") module lib.std.runtime._assert;

import lib.std.string;
import lib.std.stdio;

// ``assert`` function
extern (C) void __assert(const char* exp, const char* file, uint line) {
	putChr('[');
	putChr('!', Color.HighLight2);
	putStr("] ");

	writef("[%s:%d] %s", fromCString(file), line, fromCString(exp));
	
	// Hang the kernel
	version(X86_64) {
		asm {
			cli;
			hlt;
		}
	} else {
		while(1) {}
	}
}