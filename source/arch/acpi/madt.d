module arch.acpi.madt;

import memory.heap;
import au.types;
import io.console;

import arch.acpi;
import memory;

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

__gshared usize lapicAddr;

void initMadt() {
	// Get the MADT
	auto madt = cast(Madt*) getTable(madtSignature);
	if (madt == null)
		panic("No MADT found. Init cannot continue");
	
	log(1, "Parsing MADT");

	bool lapicOverriden = false;
	
	usize lapicCount;
	usize lapicNmiCount;
	usize ioApicCount;
	usize ioApicIsoCount;
	usize ioApicNmiSourceCount;

	// Parse and sort all MADT entries
	ubyte* entries;
	auto end = cast(usize) madt + madt.header.length;
	for (entries = cast(ubyte*) &madt.entries; cast(usize) entries < end; entries += *(entries + 1)) {
		switch (*entries) {
		case EntryType.ProccesorLapic:
			lapicInfo.append(cast(LapicInfo*) entries);
			lapicCount++;
			break;

		case EntryType.LapicNmi:
			lapicNmiInfo.append(cast(LapicNmiInfo*) entries);
			lapicNmiCount++;
			break;

		case EntryType.IoApic:
			ioApicInfo.append(cast(IoApicInfo*) entries);
			ioApicCount++;
			break;

		case EntryType.IoApicIso:
			ioApicIsoInfo.append(cast(IoApicIsoInfo*) entries);
			ioApicIsoCount++;
			break;

		case EntryType.IoApicNmiSource:
			ioApicNmiSourceInfo.append(cast(IoApicNmiSourceInfo*) entries);
			ioApicNmiSourceCount++;
			break;

		case EntryType.LapicAddrOverride:
			auto over = cast(LapicAddrOverride*) entries;
			lapicAddr = over.address;
			lapicOverriden = true;
			break;

		default:
			break;
		}
	}

	if (!lapicOverriden)
		lapicAddr = cast(usize) madt.lapicAddr;

	lapicAddr += PhysOffset;

	log(1, "MADT Parsed:
		LAPIC-Processor entries:\t%d
		LAPIC NMI entries:\t\t\t%d
		IO APIC entries:\t\t\t%d
		IO APIC ISOs:\t\t\t\t\t%d
		IO APIC NMI entries:\t\t%d",
		lapicCount, lapicNmiCount,
		ioApicCount,ioApicIsoCount,
		ioApicNmiSourceCount);

	log(1, "LAPIC Address: %h", lapicAddr);
}