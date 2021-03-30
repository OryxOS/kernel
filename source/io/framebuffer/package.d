module io.framebuffer;

/* OryxOS FrameBuffer implementation
 * This implementation is designed to only work with
 * 32 bpp screens as this simplifies the design alot, while only removing support
 * for a few devices.
 *
 * In our implementation, the screenPos(0,0) is the top left of the screen.
 */

import io.framebuffer.font;
import lib.stivale;

alias pixel = uint;

// Private and only for internal use, use ``FrameBufferInfo`` instead 
private struct FrameBuffer {
	pixel* address;
	
	uint width;
	uint height;
	uint pitch;

	shared this(shared FrameBufferTag* tag) {
		this.address = cast(shared pixel*)(tag.address);

		this.width  = tag.width;
		this.height = tag.height;
		this.pitch  = tag.pitch / 4;
	}
}

/* Useful for passing to stuff that we don't
 * want to have direct access to the framebuffer.
 */
struct FrameBufferInfo {
	uint width;
	uint height;
}

//////////////////////////////
//         Instance         //
//////////////////////////////

private shared FrameBuffer buffer;

void initFrameBuffer(StivaleInfo* stivale) {
	// Try access the FrameBufferTag passed by stivale
	shared FrameBufferTag* fb = cast(shared FrameBufferTag*)(stivale.getTag(FrameBufferID));
	
	// Very unlikely so we don't properly handle these
	assert(fb != null);
	assert(fb.bpp == 32);	

	// Tag is good
	buffer = shared FrameBuffer(fb);
}

void plotPixel(pixel p, uint x, uint y) {
	buffer.address[(buffer.pitch * y) + x] = p;
}

void plotRect(pixel p, uint x, uint y, uint width, uint height) {
	for(uint i = 0; i < height; i++) {
		int where = buffer.pitch * y + buffer.pitch * i + x;

		buffer.address[(where)..(where + width)] = p;
	}
}

void plotScreen(pixel p) {
	buffer.address[0..(buffer.pitch * buffer.height + buffer.width)] = p;
}

void plotChr(pixel fore, pixel back, char c, uint x, uint y) {
	ubyte[16] glyph = charToGlyph(c);

	/* Go through each row of the glyph,
	 * for each row, >> and & to get the value of each pixel.
	 * 1 => pixel-foreground. 0 => pixel-background.
	 * Finally, inverse x.
	 */
	for (uint i = 0; i < 15; i++) {
		for (uint j = 0; j < 7; j++) {
			if ((glyph[i] >> j & 1) == 1) {
				plotPixel(fore, x + 7 - j, i + y);
			} else {
				plotPixel(back, x + 7 - j, i + y);
			}
		}
	}
}

void scrollScreen(uint amount, uint offsetFromBottom = 0) {
	buffer.address[0..buffer.height * buffer.pitch - ((amount + offsetFromBottom) * buffer.pitch)] 
		= buffer.address[(amount * buffer.pitch)..buffer.height * buffer.pitch - offsetFromBottom * buffer.pitch];
}

FrameBufferInfo getFrameBufferInfo() {
	return FrameBufferInfo(buffer.width, buffer.height);
}