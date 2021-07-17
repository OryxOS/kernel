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
	uint   flags;
}

// Info about an IO APIC
struct IoApicInfo {
	align (1):
	EntryHeader header;
	ubyte  ident;
	ubyte  reserved;
	uint   address;
	uint   gsiBase;
}

// Info about an IO APIC Interrupt Source Override
struct IoApicIsoInfo {
	align (1):
	EntryHeader header;
	ubyte  busSource;
	ubyte  irqSource;
	uint   gsi;
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
	ubyte  ident;
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

__gshared LinkedList!(LapicInfo*)           lapicInfo;
__gshared LinkedList!(LapicNmiInfo*)        lapicNmiInfo;
__gshared LinkedList!(IoApicInfo*)          ioApicInfo;
__gshared LinkedList!(IoApicIsoInfo*)       ioApicIsoInfo;
__gshared LinkedList!(IoApicNmiSourceInfo*) ioApicNmiSourceInfo;

__gshared size_t lapicAddr;

void initMadt() {
	// Get the MADT
	auto madt = cast(Madt*) getTable(madtSignature);
	if (madt == null)
		panic("No MADT found. Init cannot continue");
	
	log(1, "Parsing MADT");

	// Parse and sort all MADT entries
	ubyte* entries;
	auto end = cast(size_t) madt + madt.header.length;
	bool lapicOverriden = false;
	for (entries = cast(ubyte*) &madt.entries; cast(size_t) entries < end; entries += *(entries + 1)) {
		switch (*entries) {
		case EntryType.ProccesorLapic:
			lapicInfo.append(cast(LapicInfo*) entries);
			log(1, "LAPIC-Processor entry found");
			break;

		case EntryType.LapicNmi:
			lapicNmiInfo.append(cast(LapicNmiInfo*) entries);
			log(1, "LAPIC NMI entry found");
			break;

		case EntryType.IoApic:
			ioApicInfo.append(cast(IoApicInfo*) entries);
			auto lmao = cast(IoApicInfo*) entries;
			log(1, "IO APIC entry found");
			break;

		case EntryType.IoApicIso:
			ioApicIsoInfo.append(cast(IoApicIsoInfo*) entries);
			log(1, "IO APIC ISO entry found");
			break;

		case EntryType.IoApicNmiSource:
			ioApicNmiSourceInfo.append(cast(IoApicNmiSourceInfo*) entries);
			log(1, "IO APIC NMI Source entry found");
			break;

		case EntryType.LapicAddrOverride:
			auto over = cast(LapicAddrOverride*) entries;
			lapicAddr = over.address;
			lapicOverriden = true;
			log(1, "LAPIC address override found");
			break;

		default:
			break;
		}
	}

	if (!lapicOverriden)
		lapicAddr = cast(size_t) madt.lapicAddr;

	log(1, "LAPIC Address: %h", lapicAddr);
}