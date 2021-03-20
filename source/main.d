import specs.stivale;
import io.framebuffer;
import io.console;

extern (C) void main(StivaleInfo* stivale) {
	initFrameBuffer(stivale);
	initConsole();

	writeln("OrxyOS booted!");
	
	stivale.displayBootInfo();

	version (X86_64) {
		import arch.amd64.memory.gdt : initGdt;
		writeln("\nAmd64 Init:");

		initGdt();
	}

	while(1){}
}