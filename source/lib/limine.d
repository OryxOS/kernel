module lib.limine;

import au.types;
import au.string;

import io.console;

// Request IDs
enum FrameBufferRequestID = [0xc7b1dd30df4c8b88, 0x0a82e883a194f07b, 0x9d5827dcd881dd75, 0xa3148604f6fab11b];
enum BootloaderInfoID     = [0xc7b1dd30df4c8b88, 0x0a82e883a194f07b, 0xf55038d8e2a1202f, 0x279426fcf5f59740];
enum MemoryMapID          = [0xc7b1dd30df4c8b88, 0x0a82e883a194f07b, 0x67cf3d9d378a806f, 0xe304acdfc50c3c62];
enum XsdtPointerID        = [0xc7b1dd30df4c8b88, 0x0a82e883a194f07b, 0xc5e77b6b397e7b43, 0x27637845accdcf3c];
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
	ulong fb_count;
	LimineFrameBufferInfo** fb_ptrs;
}

struct LimineFrameBufferInfo {
	align (1):

	void* address;

	ulong width;
	ulong height;
	ulong pitch;
	ushort bpp;

	ubyte mem_model;
	ubyte r_mask_size;
	ubyte r_mask_shift;
	ubyte g_masksize;
	ubyte g_mask_shift;
	ubyte b_mask_size;
	ubyte b_mask_shift;

	ubyte[7] unused;

	ulong edid_size;
	void* edid;
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
	ulong count;
	MemoryMapEntry** entries;
}

enum MemoryMapType: ulong {
	Usable                = 0,
	Reserved              = 1,
	AcpiReclaimable       = 2,
	AcpiNvs               = 3,
	Bad                   = 4,
	BootloaderReclaimable = 5,
	KernelOrModule        = 6,
	FrameBuffer           = 7
 }

 // Do not modify, this matches the limine spec
struct MemoryMapEntry {
	align (1):
	ulong base;
	ulong length;
	MemoryMapType type;
}

//////////////////////////////
//           ACPI           //
//////////////////////////////

struct XsdtPointerRequest {
	align (1):
	ulong[4] id;
	ulong revision;
	XsdtPointerResponse* response = null;
}

struct XsdtPointerResponse {
	align (1):
	ulong revision;
	void* address;
}

//////////////////////////////
//        Stack Size        //
//////////////////////////////

struct StackSizeRequest {
	align (1):
	ulong[4] id;
	ulong revision;
	StackSizeResponse* response = null;
	ulong desired_size;
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

struct LimineUuid {
	align(1):
	uint a;
	uint b;
	uint c;
	uint[8] d;	
}

struct LimineFile {
	align(1):
	ulong revision;
	void* address;
	ulong size;
	char* path;
	char* cmd_line;
    LimineMediaType media_type;
    uint unused;
    uint tftp_ip;
    uint tftp_port;
    uint part_index;
    uint mbr_disk_id;
    LimineUuid gpt_disk_uuid;
    LimineUuid gpt_part_uuid;
    LimineUuid part_uuid;
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

	LimineFile* get_module(string path) {
		foreach (i; 0..this.count) {
			if (from_c_string(this.modules[i].path) == path)
				return this.modules[i];
		}
		return null;
	}
}