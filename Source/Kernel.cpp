#include <Libs/Std/Types.hpp>
#include <Libs/Stivale2.hpp>
#include <HAL/Interface/Text.hpp>
#include <Common/Console.hpp>

using namespace Types;
using namespace Text;

u8 stack[4096];

__attribute__((section(".stivale2hdr"), used))
Stivale2::Header stivaleHeader = {
	.entryPoint	= 0,
	.stackAddr	= reinterpret_cast<u64>(stack) + sizeof(stack),
	.flags		= 0,
	.tags		= 0,
};

void Greet() {
	Text::SetBg(Color::White);
	Text::SetFg(Color::DarkGray);

	Text::Clear();

	PutStr(" _____                 _____ _____ ");
	PutStr("\n|  _  |               |  _  /  ___|");
	PutStr("\n| | | |_ __ _   ___  _| | | \\ \\`--. ");
	PutStr("\n| | | | '__| | | \\ \\/ / | | |\\`--. \\");
	PutStr("\n\\ \\_/ / |  | |_| |>  <\\ \\_/ /\\__/ /");
	PutStr("\n \\___/|_|   \\__, /_/\\_\\___/\\____/ ");
	PutStr("\n             __/ |                 ");
	PutStr("\n            |___/                  ");
	PutStr("\n");

	Text::SetFg(Color::Black);

	PutStr("\nBy Ethan Edwards");
}

extern "C" void Main() {
	Greet();

	Console::Log("\nHello %, %", 'C', 'F');

	while(1) {}
}
