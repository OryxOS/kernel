#include <Common/Types.hxx>
#include <Common/Stivale2.hxx>
#include <Arch/Amd64/Drivers/Display/VGA.hxx>

using namespace Types;

u8 stack[4096];

__attribute__((section(".stivale2hdr"), used))
Stivale2::Header stivaleHeader = {
    .entryPoint = 0,
    .stackAddr  = reinterpret_cast<u64>(stack) + sizeof(stack),
    .flags      = 0,
    .tags       = 0,
};

extern "C" void _start() {
	VGA::SetBg(VGA::Color::White);
	VGA::SetFg(VGA::Color::Black);

	VGA::Clear();

	for (u32 i = 0; i < 30; i++) {
		VGA::PutStr("\n Hello");
	}

	VGA::PutStr("\n Hello1");

    while(1) {}
}