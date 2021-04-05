module io.framebuffer.fancy;

import io.framebuffer;

// A bunch of fancy demos that our graphics library can do

/// Draws a big exclamation mark
void plotExclamation(uint color, uint x, uint y) {
	plotRect(color, x + 8, y, 24, 72);
	plotRect(color, x, y + 8, 40, 40);
	plotRect(color, x + 8, y + 80, 24, 24);
}