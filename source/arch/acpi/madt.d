module arch.acpi.madt;

import lib.std.heap;
import lib.std.stdio;

import arch.acpi;

/* OryxOS MADT Management
 * The Madt is a stucture that contains information
 * about all the interrupts controllers in the system
 */

private static immutable char[4] madtSignature = ['A', 'P', 'I', 'C'];

private align (1) struct Madt {
	SdtHeader header;

	uint  lapicAddr;
	uint  flags;
	void* entries;
}

private enum Type: ubyte {
	ProccesorLapic    = 0,
	IoApic            = 1,
	IoApicIso         = 2,
	IoApicNmiSource   = 3,
	LapicNmi          = 4,
	LapicAddrOverride = 5,
	Proccesorx2Lapic  = 9,
}

private align (1) struct Header {
	Type  type;
	ubyte length;
}

// Info about a LAPIC-Processor combo
align (1) struct LapicInfo {
	Header header;
	ubyte  procId;
	ubyte  apicId;    
}

// Info about an IO APIC
align (1) struct IoApicInfo {
	Header header;
	ubyte  ioApicIdent;
	ubyte  reserved;
	uint   ioApicAddr;
	uint   gsiBase;
}

// Info about an IO APIC Interrupt Source Override
align (1) struct IoApicIsoInfo {
	Header header;
	ubyte  busSource;
	ubyte  irqSource;
	ubyte  gsi;
	ushort flags;
}

// Info about an IO APIC Non-Maskable Interrupt Source
align (1) struct IoApicNmiSourceInfo {
	Header header;
	ubyte  source;
	ubyte  reserved;
	ushort flags;
	ubyte  gsi;
}

// Info about a LAPIC Non-Maskable Interrupt
align (1) struct LapicNmiInfo {
	Header header;
	ubyte  procId;
	ushort flags;
	ushort ident;
}

// Contains the 64 bit address of the lapic if available
private align(1) struct LapicAddrOverride {
	Header header;
	uint   reserved;
	ulong  address;
}

align (1) struct X2LapicInfo {
	Header header;
	uint   reserved;
	ushort apicIdent;
	uint   flags;
	uint   procIdent;
}


//////////////////////////////
//         Instance         //
//////////////////////////////

__gshared LinkedList!(LapicInfo)           lapicInfo;
__gshared LinkedList!(LapicNmiInfo)        lapicNmiInfo;
__gshared LinkedList!(IoApicInfo)          ioApicInfo;
__gshared LinkedList!(IoApicIsoInfo)       ioApicIsoInfo;
__gshared LinkedList!(IoApicNmiSourceInfo) ioApicNmiSourceInfo;

__gshared void* lapicAddr;

void initMadt() {
	// Get the MADT
	auto madt = getTable(madtSignature);
	if (madt == null)
		panic("No MADT found. Init cannot continue");

	// Look for the 64 bit lapic address, if not found, use the 32 bit one;
	//writefln("Lapic addr: %d", madt.lapicAddr);
}