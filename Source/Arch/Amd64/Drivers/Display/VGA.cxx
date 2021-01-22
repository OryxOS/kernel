#include <Common/Types.hxx>
#include <Common/Mem.hxx>
#include "VGA.hxx"

using namespace Types;

//TODO: add scroll

const u64 Width 	= 80;
const u64 Height	= 25;

u64 posX = 0;
u64 posY = 0;

VGA::Color fg = VGA::Color::Black;
VGA::Color bg = VGA::Color::White;

u16 *buffer = reinterpret_cast<u16*>(0xb8000);

void VGA::PutChar(char c) {
	if(posX > Width) {
		posY++;
		posX = 0;
	}

	if (posY > Height) {
		posY = Height;
		posX = 0;

		Mem::Copy(buffer, buffer + Width, 24 * Width);
	}

	switch (c) {
		case '\n': {
			posY++;
			posX = 0;
		}
		default: {
			buffer[posX + (Width * posY)] = static_cast<u16>(c) | ((fg | (bg << 4)) << 8);
			posX++;
		}
	}
}

void VGA::PutStr(const char* str) {
	// Strings are null terminated
	while (*str != '\0') {
		PutChar(*str++);
	}
}

void VGA::Clear() {
	posX = 0;
	posY = 0;

	for (u16 i = 0; i < Width * Height; i++) {
		buffer[i] = static_cast<u16>(' ') | ((fg | (bg << 4)) << 8);
	}
}

void VGA::SetBg(Color background) {
	bg = background;
}

void VGA::SetFg(Color foreground) {
	fg = foreground;
}