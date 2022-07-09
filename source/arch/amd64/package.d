module arch.amd64;

import lib.limine;

import au.types;

import io.console;

import arch.amd64.gdt    : init_gdt;
import arch.amd64.idt    : init_idt;
import arch.amd64.tss    : init_tss;
import arch.amd64.pic    : disablePic;
import arch.amd64.apic   : init_apic;
import arch.amd64.memory : init_vmm;
import arch.amd64.cpu;

import arch.acpi         : init_acpi;
import arch.acpi.madt    : init_madt;

extern extern (C) void init_syscalls();

void init_arch(MemoryMapResponse* map, XsdtPointerResponse* xsdt_ptr, KernelAddressResponse* k_addr) {
	writefln("\nAmd64 Init:");

	// Basic arch structures
	init_gdt();
	init_idt();
	init_tss();
	init_vmm(map, k_addr);

	// Interrupts
	init_acpi(xsdt_ptr);
	init_madt();
	disablePic();
	init_apic();
	enable_ints(true);
	
	// Syscall and sysret instructions
	init_syscalls();
}