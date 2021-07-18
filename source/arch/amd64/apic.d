module arch.amd64.apic;

import core.volatile;

import lib.util.console;

import arch.acpi.madt;

/* OryxOS APIC management
 * This code contains functions for managing LAPICs
 * and IO APICs
 */

private enum EoiRegister  = 0xB0;
private enum SpurRegister = 0xF0;
private enum IdResgister  = 0x20;

private enum SpurVector   = 0xFF;

// Reads data from a LAPIC register
private uint readLapic(size_t reg) {
	return volatileLoad(cast(uint*) (lapicAddr + reg));
}

// Writes data to a LAPIC register
private void writeLapic(size_t reg, uint val) {
	volatileStore(cast(uint*) (lapicAddr + reg), val);
}

// Reads data from an IO APIC register
private uint readIoApic(size_t ioApicId, uint reg) {
	auto base = cast(uint*) ioApicInfo[ioApicId].address;

	volatileStore(base, reg);      // Select register
	return volatileLoad(base + 4); // Read data
}

// Writes data to an IO APIC register
private void writeIoApic(size_t ioApicId, uint reg, uint data) {
	auto base = cast(uint*) ioApicInfo[ioApicId].address;

	volatileStore(base, reg);      // Select register
	volatileStore(base + 4, data); // Store data
}

// Enable the APIC and set thee spurious interrupt register
private void enableLapic() {
	writeLapic(SpurRegister, (readLapic(SpurRegister) | 0x100 | SpurVector));
}

// Returns the maximum number of redirections an IO APIC can hold
private uint maxRedirCount(size_t ioApicId) {
	return (readIoApic(ioApicId, 1) & 0xFF0000) >> 16;
}

// Determines which IO APIC handles a given gsi. Returns -1 upon failure
private size_t getIoApicFromGsi(uint gsi) {
	foreach (i; 0..ioApicInfo.getLength()) {
		// Check if GSI is in range of IO APIC
		if (ioApicInfo[i].gsiBase <= gsi && ioApicInfo[i].gsiBase + maxRedirCount(i) > gsi)
			return i;
	}

	return -1;
}

private void mapGsiToVec(ubyte vec, uint gsi, ushort flags) {
	size_t ioApicId = getIoApicFromGsi(gsi);

	if (ioApicId == -1)
		panic("TODO: APIC error handling");

	ulong redirect = vec;

	// Active on high(0) or low(1)
    if (flags & 2) {
        redirect |= (1 << 13);
    }

	// Edge(0) or level(1) triggered
    if (flags & 8) {
        redirect |= (1 << 15);
    }

	// Get the LAPIC ID (Will change with SMP)
	redirect |= cast(ulong) readLapic(IdResgister) << 56;

	uint register = (gsi - ioApicInfo[ioApicId].gsiBase) * 2 + 16;

	// Load register in 2 parts
	writeIoApic(ioApicId, register + 0, cast(uint) redirect);
	writeIoApic(ioApicId, register + 1, cast(uint) (redirect >> 32));

}

void enableLegacyIrq(ubyte irq) {
	alias isos = ioApicIsoInfo;

	// Check If irq has been overriden by an ISO
	foreach (i; 0..isos.getLength()) {
		if (isos[i].irqSource == irq) {
			mapGsiToVec(cast(ubyte) (isos[i].irqSource + 0x20), isos[i].gsi, isos[i].flags);
			return;
		}
	}

	// Interrupt not overriden
	mapGsiToVec(cast(ubyte) (irq + 0x20), irq, 0);
}

void endInterrupt() {
	writeLapic(EoiRegister, 0);
}

void initApic() {
	enableLapic();
	enableLegacyIrq(1);

	log(1, "APIC enabled");
}