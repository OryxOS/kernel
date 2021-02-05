#include <Libs/Std/Types.hpp>
#include <HAL/Interface/Buffer.hpp>
#include <HAL/Interface/Text.hpp>

using namespace Types;

u64 posX = 0;
u64 posY = 0;

Text::Color fg = Text::Color::Black;
Text::Color bg = Text::Color::White;

u16 *buffer = reinterpret_cast<u16*>(0xb8000);

void Text::PutChr(char c) {
	if(posX > 80) {
		posY++;
		posX = 0;
	}

	if (posY >= 25) {
		posY = 24;
		posX = 0;

		// Scroll
		Buffer::Copy(buffer + 80, buffer, 24 * 80 * 2);
		for (u16 i = 0; i < 80; i++) {
			buffer[80 * 24 + i] = static_cast<u16>(' ') | ((fg | (bg << 4)) << 8);
		}
	}

	switch (c) {
		case '\n': {
			posY++;
			posX = 0;
			break;
		}
		default: {
			buffer[posX + 80 * posY] = static_cast<u16>(c) | ((fg | (bg << 4)) << 8);
			posX++;
			break;
		}
	}
}

void Text::PutStr(const char* str) {
	// Strings are null terminated
	while (*str != '\0') {
		PutChr(*str++);
	}
}

void Text::Clear() {
	posX = 0;
	posY = 0;

	for (u16 i = 0; i < 80 * 25; i++) {
		buffer[i] = static_cast<u16>(' ') | ((fg | (bg << 4)) << 8);
	}
}

void Text::SetBg(Color background) {
	bg = background;
}

void Text::SetFg(Color foreground) {
	fg = foreground;
}