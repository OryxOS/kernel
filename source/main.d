import io.console;
import io.framebuffer;
import specs.stivale;

extern (C) void main(StivaleInfo* stivale) {
	initFrameBuffer(stivale);

	plotScreen(0x0D1117);

	//writeln("Hello World, The answer is ", 42, " When");

	for (int i = 0; i < 250; i++) {
		write("h");
	}

	ushort x = 120;
	ushort y = 5;
	uint color = 0xC9D1D9;

	while (true) {
		plotRect(color, x, y, 10, 10);

		x += 15;

		if (x > 512) {
			x = 120;
			y += 15;
		}

		if (y > 512) {
			x = 120;
			y = 5;
		}

		color += 10;
	}

	/*writeln("OryxOS booted!");

	version(X86_64) {
		import arch.amd64.memory.gdt : initGdt;
		writeln("Amd64 Initialization process");

		initGdt();
	}
	*/

	while(1){}
}