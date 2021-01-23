#include <Common/Types.hxx>
#include <Libs/Stivale2.hxx>
#include <Arch/Amd64/Drivers/Display/VGA.hxx>

using namespace Types;

u8 stack[4096];

__attribute__((section(".stivale2hdr"), used))
Stivale2::Header stivaleHeader = {
	.entryPoint	= 0,
	.stackAddr	= reinterpret_cast<u64>(stack) + sizeof(stack),
	.flags		= 0,
	.tags		= 0,
};

extern "C" void Main() {
	VGA::SetBg(VGA::Color::White);
	VGA::SetFg(VGA::Color::Blue);

	VGA::Clear();

	VGA::PutStr("\n _____                 _____ _____ ");
	VGA::PutStr("\n|  _  |               |  _  /  ___|");
	VGA::PutStr("\n| | | |_ __ _   ___  _| | | \\ \\`--. ");
	VGA::PutStr("\n| | | | '__| | | \\ \\/ / | | |\\`--. \\");
	VGA::PutStr("\n\\ \\_/ / |  | |_| |>  <\\ \\_/ /\\__/ /");
	VGA::PutStr("\n \\___/|_|   \\__, /_/\\_\\___/\\____/ ");
	VGA::PutStr("\n             __/ |                 ");
	VGA::PutStr("\n            |___/                  ");
	VGA::PutStr("\n");

	VGA::SetFg(VGA::Color::Black);

	VGA::PutStr("\nBy Ethan Edwards");

	while(1) {}
}