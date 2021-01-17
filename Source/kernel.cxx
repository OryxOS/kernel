#include "Libraries/Types.hxx"
#include "Libraries/Stivale2.hxx"

using namespace Types;

u8 stack[4096];

__attribute__((section(".stivale2hdr"), used))
Stivale2::Header stivaleHeader = {
    .entryPoint = 0,
    .stackAddr  = (u64)stack + sizeof(stack),
    .flags      = 0,
    .tags       = 0,
};

extern "C" void _start() {
    char* vmem = (char*)0xB8000;
    *vmem = 'H';
    
    while(1) {}
}
