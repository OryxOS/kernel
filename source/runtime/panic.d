module runtime.panic;

import runtime.string;
import io.console;

// ``assert`` function
extern (C) void __assert(const char* exp, const char* file, uint line) {
	writeln();
	log(LogLevel.Error, 0, "Assert:", fromCString(exp));
	writeln("    Where: ", fromCString(file), ":", line);

	while(1) {} // Hang the kernel
}