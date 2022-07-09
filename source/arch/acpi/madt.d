module arch.acpi.madt;

import lib.collections;
import au.types;
import io.console;

import arch.acpi;
import memory;

/* OryxOS MADT Management
 * The Madt is a stucture that contains information
 * about all the interrupts controllers in the system
 */

private static immutable char[4] MadtSignature = ['A', 'P', 'I', 'C'];

private struct Madt {
	align (1):
	SdtHeader header;
	uint lapic_addr;
	uint flags;
	void* entries;
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
	ubyte length;
}

// Info about a LAPIC-Processor combo
struct LapicInfo {
	align (1):
	EntryHeader header;
	ubyte processor_id;
	ubyte apicId;
	uint flags;
}

// Info about an IO APIC
struct IoApicInfo {
	align (1):
	EntryHeader header;
	ubyte ident;
	ubyte reserved;
	uint address;
	uint gsi_base;
}

// Info about an IO APIC Interrupt Source Override
struct IoApicIsoInfo {
	align (1):
	EntryHeader header;
	ubyte bus_source;
	ubyte irq_source;
	uint gsi;
	ushort flags;
}

// Info about an IO APIC Non-Maskable Interrupt Source
struct IoApicNmiSourceInfo {
	align (1):
	EntryHeader header;
	ubyte source;
	ubyte reserved;
	ushort flags;
	ubyte gsi;
}

// Info about a LAPIC Non-Maskable Interrupt
struct LapicNmiInfo {
	align (1):
	EntryHeader header;
	ubyte processor_id;
	ushort flags;
	ubyte id;
}

// Contains the 64 bit address of the lapic if available
private struct LapicAddrOverride {
	align (1):
	EntryHeader header;
	uint reserved;
	ulong address;
}

struct X2LapicInfo {
	align (1):
	EntryHeader header;
	uint reserved;
	ushort apic_id;
	uint flags;
	uint processor_id;
}


//////////////////////////////
//         Instance         //
//////////////////////////////

__gshared LinkedList!(LapicInfo*)           lapic_list;
__gshared LinkedList!(LapicNmiInfo*)        lapic_nmi_list;
__gshared LinkedList!(IoApicInfo*)          io_apic_list;
__gshared LinkedList!(IoApicIsoInfo*)       io_apic_iso_list;
__gshared LinkedList!(IoApicNmiSourceInfo*) io_apic_nmi_src_list;

__gshared usize lapic_addr;

void init_madt() {
	// Locate the MADT table
	auto madt = cast(Madt*) get_table(MadtSignature);

	assert(madt != null, "No MADT found. Init cannot continue");
	
	log(1, "Parsing MADT");

	bool lapic_overriden = false;
	
	usize lapics;
	usize lapic_nmis;
	usize io_apics;
	usize io_apic_isos;
	usize io_apic_nmi_sources;

	// Parse and sort all MADT entries
	ubyte* entries;
	auto end = cast(usize) madt + madt.header.length;
	for (entries = cast(ubyte*) &madt.entries; cast(usize) entries < end; entries += *(entries + 1)) {
		switch (*entries) {
		case EntryType.ProccesorLapic:
			lapic_list.append(cast(LapicInfo*) entries);
			lapics++;
			break;

		case EntryType.LapicNmi:
			lapic_nmi_list.append(cast(LapicNmiInfo*) entries);
			lapic_nmis++;
			break;

		case EntryType.IoApic:
			io_apic_list.append(cast(IoApicInfo*) entries);
			io_apics++;
			break;

		case EntryType.IoApicIso:
			io_apic_iso_list.append(cast(IoApicIsoInfo*) entries);
			io_apic_isos++;
			break;

		case EntryType.IoApicNmiSource:
			io_apic_nmi_src_list.append(cast(IoApicNmiSourceInfo*) entries);
			io_apic_nmi_sources++;
			break;

		case EntryType.LapicAddrOverride:
			auto over = cast(LapicAddrOverride*) entries;
			lapic_addr = over.address;
			lapic_overriden = true;
			break;

		default:
			break;
		}
	}

	if (!lapic_overriden)
		lapic_addr = cast(usize) madt.lapic_addr;

	lapic_addr += PhysOffset;

	log(1, "MADT Parsed:
		LAPIC-Processor entries:\t%d
		LAPIC NMI entries:\t\t\t%d
		IO APIC entries:\t\t\t%d
		IO APIC ISOs:\t\t\t\t\t%d
		IO APIC NMI entries:\t\t%d",
		lapics, lapic_nmis,
		io_apics,io_apic_isos,
		io_apic_nmi_sources);

	log(1, "LAPIC Address: %h", lapic_addr);
}