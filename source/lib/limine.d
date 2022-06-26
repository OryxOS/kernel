module lib.limine;

import au.types;
import au.string;
import io.console;

import common.memory.map;

// Request IDs
enum FrameBufferRequestID = [0xc7b1dd30df4c8b88, 0x0a82e883a194f07b, 0x9d5827dcd881dd75, 0xa3148604f6fab11b];
enum BootloaderInfoID     = [0xc7b1dd30df4c8b88, 0x0a82e883a194f07b, 0xf55038d8e2a1202f, 0x279426fcf5f59740];
enum MemoryMapID          = [0xc7b1dd30df4c8b88, 0x0a82e883a194f07b, 0x67cf3d9d378a806f, 0xe304acdfc50c3c62];
enum XSDTPointerID        = [0xc7b1dd30df4c8b88, 0x0a82e883a194f07b, 0xc5e77b6b397e7b43, 0x27637845accdcf3c];
enum StackSizeID          = [0xc7b1dd30df4c8b88, 0x0a82e883a194f07b, 0x224ef0460a8e8926, 0xe1cb0fc25f46ea3d];
enum HigherHalfID         = [0xc7b1dd30df4c8b88, 0x0a82e883a194f07b, 0x48dcf1cb8ad2b852, 0x63984e959a98244b];
enum KernelAddressID      = [0xc7b1dd30df4c8b88, 0x0a82e883a194f07b, 0x71ba76863cc55f63, 0xb2644a48c516a487];
enum ModuleID             = [0xc7b1dd30df4c8b88, 0x0a82e883a194f07b, 0x3e7e279702be32af, 0xca1c4f3bd1280cee];

//////////////////////////////
//      Bootloader Info     //
//////////////////////////////

struct BootloaderInfoRequest {
	align (1):
	ulong[4] id;
	ulong revision;
	BootloaderInfoResponse* response = null;
}

struct BootloaderInfoResponse {
	align (1):
    ulong revision;
    char* name;
	char* vers;
}

//////////////////////////////
//       FrameBuffer        //
//////////////////////////////

struct FrameBufferRequest {
	align (1):
	ulong[4] id;
	ulong revision;
	FrameBufferResponse* response = null;
}

struct FrameBufferResponse {
	align (1):
	ulong revision;
	ulong frameBufferCount;
	LimineFrameBufferInfo** framebuffers;
}

struct LimineFrameBufferInfo {
	align (1):

	void* address;

	ulong width;
	ulong height;
	ulong pitch;
	ushort bpp;

	ubyte memoryModel;
	ubyte rMaskSize;
	ubyte rMaskShift;
	ubyte gMaskSize;
	ubyte gMaskShift;
	ubyte bMaskSize;
	ubyte bMaskShift;

	ubyte[7] unused;

	ulong edidSize;
	VirtAddress edid;
}

//////////////////////////////
//        Memory Map        //
//////////////////////////////

struct MemoryMapRequest {
	align (1):
	ulong[4] id;
	ulong revision;
	MemoryMapResponse* response = null;
}

struct MemoryMapResponse {
	align (1):
	ulong revision;
	ulong entryCount;
	Region** entries;
}

//////////////////////////////
//           ACPI           //
//////////////////////////////

struct XSDTPointerRequest {
	align (1):
	ulong[4] id;
	ulong revision;
	XSDTPointerResponse* response = null;
}

struct XSDTPointerResponse {
	align (1):
	ulong revision;
	VirtAddress address;
}

//////////////////////////////
//        Stack Size        //
//////////////////////////////

struct StackSizeRequest {
	align (1):
	ulong[4] id;
	ulong revision;
	StackSizeResponse* response = null;
	ulong desiredSize;
}

struct StackSizeResponse {
	align (1):
	ulong revision;
}

//////////////////////////////
//        Higher Half       //
//////////////////////////////

struct HigherHalfRequest {
	align (1):
	ulong[4] id;
	ulong revision;
	HigherHalfResponse* response = null;
}

struct HigherHalfResponse {
	align (1):
	ulong revision;
	ulong offset;
}

//////////////////////////////
//      Kernel Address      //
//////////////////////////////

struct KernelAddressRequest {
	align (1):
	ulong[4] id;
	ulong revision;
	KernelAddressResponse* response = null;
}

struct KernelAddressResponse {
	align (1):
	ulong revision;
	ulong physBase;
	ulong virtBase;
}

//////////////////////////////
//       Limine File        //
//////////////////////////////

enum LimineMediaType: uint {
	Generic = 0,
	Optical = 1,
	TFTP    = 2,
}

struct LimineUUID {
	align(1):
	uint a;
	uint b;
	uint c;
	uint[8] d;	
}

struct LimineFile {
	align(1):
	ulong revision;
	VirtAddress address;
	ulong size;
	char* path;
	char* cmdLine;
    LimineMediaType mediaType;
    uint unused;
    uint tftpIP;
    uint tftpPort;
    uint partIndex;
    uint mbrDiskId;
    LimineUUID gptDiskUUID;
    LimineUUID gptPartUUID;
    LimineUUID partUUID;
}

//////////////////////////////
//          Module          //
//////////////////////////////

struct ModuleRequest {
	align (1):
	ulong[4] id;
	ulong revision;
	ModuleResponse* response = null;
}

struct ModuleResponse {
	align (1):
	ulong revision;
	ulong count;
	LimineFile** modules;

	LimineFile* getModule(string path) {
		foreach (i; 0..this.count) {
			if (fromCString(this.modules[i].path) == path)
				return this.modules[i];
		}
		return null;
	}
}