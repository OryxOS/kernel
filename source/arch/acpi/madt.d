module arch.acpi.madt;

import lib.util.heap;
import lib.util.console;

import arch.acpi;

/* OryxOS MADT Management
 * The Madt is a stucture that contains information
 * about all the interrupts controllers in the system
 */

private static immutable char[4] madtSignature = ['A', 'P', 'I', 'C'];

private struct Madt {
	align (1):
	SdtHeader header;
	uint      lapicAddr;
	uint      flags;
	void*     entries;
}

private enum EntryType: ubyte {
	ProccesorLapic    = 0,
	IoApic            = 1,
	IoApicIso         = 2,
	IoApicNmiSource   = 3,
	LapicNmi          = 4,
	LapicAddrOverride = 5,
	Proccesorx2Lapic  = 9,
}

private struct EntryHeader {
	align (1):
	EntryType type;
	ubyte     length;
}

// Info about a LAPIC-Processor combo
struct LapicInfo {
	align (1):
	EntryHeader header;
	ubyte  procId;
	ubyte  apicId;    
}

// Info about an IO APIC
struct IoApicInfo {
	align (1):
	EntryHeader header;
	ubyte  ioApicIdent;
	ubyte  reserved;
	uint   ioApicAddr;
	uint   gsiBase;
}

// Info about an IO APIC Interrupt Source Override
struct IoApicIsoInfo {
	align (1):
	EntryHeader header;
	ubyte  busSource;
	ubyte  irqSource;
	ubyte  gsi;
	ushort flags;
}

// Info about an IO APIC Non-Maskable Interrupt Source
struct IoApicNmiSourceInfo {
	align (1):
	EntryHeader header;
	ubyte  source;
	ubyte  reserved;
	ushort flags;
	ubyte  gsi;
}

// Info about a LAPIC Non-Maskable Interrupt
struct LapicNmiInfo {
	align (1):
	EntryHeader header;
	ubyte  procId;
	ushort flags;
	ushort ident;
}

// Contains the 64 bit address of the lapic if available
private struct LapicAddrOverride {
	align (1):
	EntryHeader header;
	uint   reserved;
	ulong  address;
}

struct X2LapicInfo {
	align (1):
	EntryHeader header;
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
}