#include <Common/Types.hxx>
#include "VGA.hxx"

using namespace Types;

//TOMMOROW: Add PutStr, Clear, Scroll, implement scrolling for boh PutChar and PutStr.
//			Also figure out inlining

const u64 Width 	= 80;
//const u64 Height	= 25;

u16 *buffer = reinterpret_cast<u16*>(0xb8000);

u64 posX = 0;
u64 posY = 0;

VGA::Color fg = VGA::Color::Black;
VGA::Color bg = VGA::Color::White;

void VGA::PutChar(char c) {
	if(posX > Width) {
		posY++;
		posX = 0;
	}

	switch (c) {
		case '\n': {
			posY++;
			posX = 0;
		}
		default: {
			buffer[posX + (80 * posY)] = static_cast<u16>(c) | ((fg | (bg << 4)) << 8);
			posX++;
		}
	}
}

void VGA::SetBg(Color background) {
	bg = background;
}

void VGA::SetFg(Color foreground) {
	fg = foreground;
}