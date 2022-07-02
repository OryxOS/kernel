import lib.limine;
import au.string;
import io.console;

import shell           : shellMain;
import io.framebuffer  : initFrameBuffer;
import memory.physical : initPmm;
import memory.alloc    : initAlloc;
import scheduler       : initScheduler;

version (X86_64) import arch.amd64;
version (X86_64) import arch.amd64.drivers.legacy.keyboard;

align(8) __gshared FrameBufferRequest frameBufferRequest       = FrameBufferRequest(FrameBufferRequestID, 0);
align(8) __gshared BootloaderInfoRequest bootloaderInfoRequest = BootloaderInfoRequest(BootloaderInfoID, 0);
align(8) __gshared MemoryMapRequest memoryMapRequest           = MemoryMapRequest(MemoryMapID, 0);
align(8) __gshared XSDTPointerRequest xsdtPointerRequest       = XSDTPointerRequest(XSDTPointerID, 0);
align(8) __gshared StackSizeRequest stackSizeRequest           = StackSizeRequest(StackSizeID, 0, null, 32768);
align(8) __gshared HigherHalfRequest higherHalfRequest         = HigherHalfRequest(HigherHalfID, 0);
align(8) __gshared KernelAddressRequest kernelAddressRequest   = KernelAddressRequest(KernelAddressID, 0);
align(8) __gshared ModuleRequest moduleRequest                 = ModuleRequest(ModuleID, 0);


extern (C) void main() {	
	initFrameBuffer(frameBufferRequest.response);
	initConsole();

	writefln("OryxOS Booted");
	writefln("\nBootloader: %s", 
		fromCString(bootloaderInfoRequest.response.name), 
		fromCString(bootloaderInfoRequest.response.vers)
	);

	initPmm(memoryMapRequest.response);
	initAlloc();

	initArch(memoryMapRequest.response, xsdtPointerRequest.response, kernelAddressRequest.response);

	initScheduler(moduleRequest.response);

	while (1) {}
}