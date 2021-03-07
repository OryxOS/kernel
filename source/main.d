import io.console;

extern (C) void main() {
	clear();

	writeln("OryxOS booted!");

	version(X86_64) {
		import arch.amd64.memory.gdt : initGdt;
		writeln("Amd64 Initialization process");

		initGdt();
	}

	while(1){}
}