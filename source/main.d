import specs.stivale;
import io.framebuffer;
import io.console;

extern (C) void main(StivaleInfo* stivale) {
	initFrameBuffer(stivale);
	initConsole();

	/*for (ulong i = 0; i < 256; i++) {
		writeln("%d", i);
	}*/

	writeln("OryxOS Booted");
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