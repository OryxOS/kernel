module io.framebuffer;

/* OryxOS FrameBuffer implementation
 * This implementation is designed to only work with
 * 32 bpp screens as this simplifies the design alot, while only removing support
 * for a few devices.
 *
 * In our implementation, the screenPos(0,0) is the top left of the screen.
 */

import io.framebuffer.font;
import lib.limine;

alias pixel = uint;

/* Private and only for internal use, use ``FrameBufferInfo`` instead. 
 * Using a different structure allows to free bootloader resources later.
 */
private struct FrameBuffer {
	pixel* address;
	ulong width;
	ulong height;
	ulong pitch;

	this (LimineFrameBufferInfo* tag) {
		this.address = cast(pixel*) tag.address;

		this.width  = tag.width;
		this.height = tag.height;
		this.pitch  = tag.pitch / 4;
	}
}

/* Useful for passing to stuff that we don't
 * want to have direct access to the framebuffer.
 */
struct FrameBufferInfo {
	ulong width;
	ulong height;
}

//////////////////////////////
//         Instance         //
//////////////////////////////

private __gshared FrameBuffer buffer;

void initFrameBuffer(FrameBufferResponse* fbInfo) {
	// Try access the FrameBuffer information
 	LimineFrameBufferInfo* fb = fbInfo.framebuffers[0];

	// Very unlikely so we don't properly handle these
	assert(fb != null);
	assert(fb.bpp == 32);	

	// Info structure is good for use
	buffer = FrameBuffer(fb);
}

void plotPixel(pixel p, ulong x, ulong y) {
	buffer.address[(buffer.pitch * y) + x] = p;
}

void plotRect(pixel p, ulong x, ulong y, ulong width, ulong height) {
	for(ulong i = 0; i < height; i++) {
		ulong where = buffer.pitch * y + buffer.pitch * i + x;

		buffer.address[(where)..(where + width)] = p;
	}
}

void plotScreen(pixel p) {
	buffer.address[0..(buffer.pitch * buffer.height)] = p;
}

void plotChr(pixel fore, pixel back, char c, ulong x, ulong y) {
	ubyte[16] glyph = charToGlyph(c);

	/* Go through each row of the glyph,
	 * for each row, >> and & to get the value of each pixel.
	 * 1 => pixel-foreground. 0 => pixel-background.
	 * Finally, inverse x.
	 */
	for (ulong i = 0; i < 16; i++) {
		for (ulong j = 0; j < 8; j++) {
			if ((glyph[i] >> j & 1) == 1)
				plotPixel(fore, x + 7 - j, i + y);
			else
				plotPixel(back, x + 7 - j, i + y);
		}
	}
}

void scrollScreen(ulong amount, ulong offsetFromBottom = 0) {
	buffer.address[0..((buffer.height - amount - offsetFromBottom) * buffer.pitch)] 
		= buffer.address[amount * buffer.pitch..(buffer.height - offsetFromBottom) * buffer.pitch];
}

FrameBufferInfo getFrameBufferInfo() {
	return FrameBufferInfo(buffer.width, buffer.height);
}