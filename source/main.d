import specs.stivale;
import io.framebuffer;
import io.console;

extern (C) void main(StivaleInfo* stivale) {
	initFrameBuffer(stivale);
	initConsole();

	writeln("OrxyOS booted!");
	
	stivale.displayBootInfo();

	version (X86_64) {
		import arch.amd64.gdt             : initGdt;
		import arch.amd64.memory.physical : initPmm;
		writeln("\nAmd64 Init:");

		initGdt();
		initPmm(stivale);
	}

	asm { hlt; }
}