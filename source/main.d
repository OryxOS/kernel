import io.console;
import io.framebuffer;
import specs.stivale;

extern (C) void main(StivaleInfo* stivale) {
	initFrameBuffer(stivale);

	plotScreen(0x0D1117);

	plotChar(0xC9D1D9, 0xD1117, 'O', 0, 0);
	plotChar(0xC9D1D9, 0xD1117, 'r', 8, 0);
	plotChar(0xC9D1D9, 0xD1117, 'y', 16, 0);
	plotChar(0xC9D1D9, 0xD1117, 'x', 24, 0);

	plotChar(0xC9D1D9, 0xD1117, ' ', 32, 0);
	plotChar(0xC9D1D9, 0xD1117, 'O', 40, 0);
	plotChar(0xC9D1D9, 0xD1117, 'S', 48, 0);

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