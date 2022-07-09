import lib.limine;
import au.string;
import io.console;

import io.framebuffer   : init_fb;
import memory.physical  : init_pmm;
import memory.allocator : init_alloc;
import scheduler        : init_shed;

version (X86_64) import arch.amd64;
version (X86_64) import arch.amd64.drivers.legacy.keyboard;

align(8) __gshared FrameBufferRequest frameBufferRequest       = FrameBufferRequest(FrameBufferRequestID, 0);
align(8) __gshared BootloaderInfoRequest bootloaderInfoRequest = BootloaderInfoRequest(BootloaderInfoID, 0);
align(8) __gshared MemoryMapRequest memoryMapRequest           = MemoryMapRequest(MemoryMapID, 0);
align(8) __gshared XsdtPointerRequest xsdtPointerRequest       = XsdtPointerRequest(XsdtPointerID, 0);
align(8) __gshared StackSizeRequest stackSizeRequest           = StackSizeRequest(StackSizeID, 0, null, 32768);
align(8) __gshared HigherHalfRequest higherHalfRequest         = HigherHalfRequest(HigherHalfID, 0);
align(8) __gshared KernelAddressRequest kernelAddressRequest   = KernelAddressRequest(KernelAddressID, 0);
align(8) __gshared ModuleRequest moduleRequest                 = ModuleRequest(ModuleID, 0);


extern (C) void main() {	
	init_fb(frameBufferRequest.response);
	init_console();

	writefln("OryxOS Booted");
	writefln("\nBootloader: %s", 
		from_c_string(bootloaderInfoRequest.response.name), 
		from_c_string(bootloaderInfoRequest.response.vers)
	);

	init_pmm(memoryMapRequest.response);
	init_alloc();

	init_arch(memoryMapRequest.response, xsdtPointerRequest.response, kernelAddressRequest.response);

	init_shed(moduleRequest.response);

	while (1) {}
}