module arch.amd64.apic;

/* OryxOS APIC management
 * This code contains functions for managing LAPICs
 * and IO APICs
 */

import core.volatile;

import au.types;

import io.console;

import memory;
import arch.acpi.madt;

private enum EoiRegister  = 0xB0;
private enum SpurRegister = 0xF0;
private enum IdResgister  = 0x20;

private enum SpurVector   = 0xFF;

// Reads data from a LAPIC register
private uint read_lapic(usize reg) {
	return volatileLoad(cast(uint*) (lapic_addr + reg));
}

// Writes data to a LAPIC register
private void write_lapic(usize reg, uint val) {
	volatileStore(cast(uint*) (lapic_addr + reg), val);
}

// Reads data from an IO APIC register
private uint read_io_apic(usize ioApicId, uint reg) {
	auto base = cast(uint*) (io_apic_list[ioApicId].address + PhysOffset);

	volatileStore(base, reg);      // Select register
	return volatileLoad(base + 4); // Read data
}

// Writes data to an IO APIC register
private void write_io_apic(usize ioApicId, uint reg, uint data) {
	auto base = cast(uint*) (io_apic_list[ioApicId].address + PhysOffset);

	volatileStore(base, reg);      // Select register
	volatileStore(base + 4, data); // Store data
}

// Enable the APIC and set thee spurious interrupt register
private void enable_lapic() {
	write_lapic(SpurRegister, (read_lapic(SpurRegister) | 0x100 | SpurVector));
}

// Returns the maximum number of redirections an IO APIC can hold
private uint max_redirs(usize io_apic_id) {
	return (read_io_apic(io_apic_id, 1) & 0xFF0000) >> 16;
}

// Determines which IO APIC handles a given gsi. Returns -1 upon failure
private isize io_apic_from_gsi(uint gsi) {
	foreach (i; 0..io_apic_list.get_length()) {
		// Check if GSI is in range of IO APIC
		if (io_apic_list[i].gsi_base <= gsi && io_apic_list[i].gsi_base + max_redirs(i) > gsi)
			return i;
	}

	return -1;
}

private void map_gsi_to_vec(ubyte vec, uint gsi, ushort flags) {
	usize io_apic_id = io_apic_from_gsi(gsi);

	assert(io_apic_id != -1, "Failed to map GSI to interrupt vector");

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
	redirect |= cast(ulong) read_lapic(IdResgister) << 56;

	uint register = (gsi - io_apic_list[io_apic_id].gsi_base) * 2 + 16;

	// Load register in 2 parts
	write_io_apic(io_apic_id, register + 0, cast(uint) redirect);
	write_io_apic(io_apic_id, register + 1, cast(uint) (redirect >> 32));

}

void enable_legacy_irq(ubyte irq) {
	alias isos = io_apic_iso_list;

	// Check If irq has been overriden by an ISO
	foreach (i; 0..isos.get_length()) {
		if (isos[i].irq_source == irq) {
			map_gsi_to_vec(cast(ubyte) (isos[i].irq_source + 0x20), isos[i].gsi, isos[i].flags);
			return;
		}
	}

	// Interrupt not overriden
	map_gsi_to_vec(cast(ubyte) (irq + 0x20), irq, 0);
}

void end_interrupt() {
	write_lapic(EoiRegister, 0);
}

void init_apic() {
	enable_lapic();
	enable_legacy_irq(1);
	log(1, "APIC enabled");
}