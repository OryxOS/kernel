module io.framebuffer;

/* OryxOS FrameBuffer implementation
 * This implementation is designed to only work with
 * 32 bpp screens as this simplifies the design alot, while only removing support
 * for a few devices.
 *
 * In our implementation, the screenPos(0,0) is the top left of the screen.
 */

import support.specs.stivale;

private alias pixel = uint;

private struct FrameBuffer {
	pixel* address;
	
	// Realisticly, Oryx isn't going to encounter a screen bigger than 4k
	ushort width;
	ushort height;
	ushort pitch;

	this(FrameBufferTag* tag) {
		this.address = cast(uint*)(tag.address);

		this.width  = tag.width;
		this.height = tag.height;
		this.pitch  = tag.pitch / 4;
	}
}

//////////////////////////////
//         Instance         //
//////////////////////////////

private __gshared FrameBuffer buffer;

void initFrameBuffer(StivaleInfo* stivale) {
	// Try access the FrameBufferTag passed by stivale
	FrameBufferTag* fb = cast(FrameBufferTag*)(stivale.getTag(FRAMEBUFFER_ID));
	
	// Very unlikely so we don't properly handle these
	assert(fb != null);
	assert(fb.bpp == 4);	

	// Tag is good
	buffer = FrameBuffer(fb);
}

void plotPixel(pixel p, ushort x, ushort y) {
	buffer.address[(buffer.pitch * y) + x] = p;
}

void plotRect(pixel p, ushort x, ushort y, ushort height, ushort width) {
	for(ushort i = 0; i < height; i++) {
		int where = buffer.pitch * y + buffer.pitch * i + x;

		buffer.address[(where)..(where + width)] = p;
	}
}

void plotScreen(pixel p) {
	buffer.address[0..(buffer.pitch * buffer.height + buffer.width)] = p;
}