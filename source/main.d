import specs.stivale;
import io.framebuffer;

extern (C) void main(StivaleInfo* stivale) {
	initFrameBuffer(stivale);

	plotScreen(0x0D1117);

	uint mX = getFrameBufferInfo().width;
	uint mY = getFrameBufferInfo().height;

	uint x = 0;
	uint y = 0;
	uint color = 0xC9D1D9;

	while (true) {
		plotRect(color, x, y, 10, 10);

		x += 15;

		if (x > mX) {
			x = 0;
			y += 15;
		}

		if (y > mY) {
			x = 0;
			y = 0;
		}

		color += 10;
	}

	while(1){}
}