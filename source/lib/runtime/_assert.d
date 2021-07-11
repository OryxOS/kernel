deprecated("Compiler intrinsics. Do not invoke") module lib.util.runtime._assert;

import lib.util.string;
import lib.util.console;

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