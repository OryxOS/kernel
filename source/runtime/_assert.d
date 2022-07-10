deprecated("Compiler intrinsics. Do not invoke") module runtime._assert;

import au.string;
import io.console;

// called on assert()
extern (C) void __assert(const char* exp, const char* file, uint line) {
	put_chr('[');
	put_chr('!', colours[2]);
	put_str("] ");

	writefln("Non-recoverable error has occured at [%s:%d]: \"%s\"", 
	         from_c_string(file),
			 line,
			 from_c_string(exp)
	);

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