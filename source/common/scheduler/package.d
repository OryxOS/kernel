module common.scheduler;

import lib.elf;
import lib.stivale;
import lib.util.math; 
import lib.util.types;
import lib.util.string;
import lib.util.console;

import common.memory;
import common.memory.physical;

version (X86_64) import arch.amd64.cpu;
version (X86_64) import arch.amd64.memory;

extern extern (C) void jumpUserSpace(VirtAddress start, VirtAddress stack);

struct Process {
	Registers    registers;
	AddressSpace addressSpace;
	VirtAddress  stack;
	VirtAddress  entry;


	// Creates a new userspace context from an ELF file
	this(Elf64Header* header) {
		this.addressSpace = AddressSpace(newBlock()
										.unwrapResult("Not enough space for process's PML Tables"));

		usize stackBottom = cast(usize) newBlock().unwrapResult("Not enough space for stack");

		this.stack = cast(VirtAddress) (stackBottom + PageSize);
		this.entry = cast(VirtAddress) (header.entry);

		// Map kernel and higher half
		auto procTables = cast(ulong[512]*) this.addressSpace.pml4;
		auto kernTables = cast(ulong[512]*) kernelSpace.pml4;

		(*procTables)[256] = (*kernTables)[256]; // Higher half
		(*procTables)[511] = (*kernTables)[511]; // Kernel

		// Map process's stack
		this.addressSpace.mapPage(cast(VirtAddress) stackBottom, cast(PhysAddress) stackBottom,
								  EntryFlags.Present | EntryFlags. Writeable | EntryFlags.UserAccessable);

		
		// Load and map all program headers
		auto progHeaders = cast(usize) header + header.progHeaderOffset;
		foreach (i; 0..header.progHeaderCount) {
			auto hdr = cast(ElfProgramHeader*) (progHeaders + i * ElfProgramHeader.sizeof);
			
			if (hdr.type == ElfProgramHeader.Type.Load) {
				// Map the section into the process' address space
				usize physStart = alignDown(cast(usize) header + hdr.offset - PhysOffset, PageSize);
				usize virtStart = alignDown(hdr.virtAddr, PageSize);
				usize pageCount = divRoundUp(hdr.memSize, PageSize);

				for (usize j = 0; j < pageCount; j++) {
					this.addressSpace.mapPage(cast(VirtAddress) (virtStart + j * PageSize), cast(PhysAddress) (physStart + j * 4096),
								  EntryFlags.Present | EntryFlags. Writeable | EntryFlags.UserAccessable);
				}
			}
		}
	}

	void start() {
		this.addressSpace.setActive();
		jumpUserSpace(this.entry, this.stack);
	}
}

void initScheduler(StivaleInfo* stivale) {
	auto moduleTag = cast(ModuleTag*) stivale.getTag(ModuleID);

	auto shellElfModule = moduleTag.getModule("application.shell");

	if (shellElfModule == null)
		panic("No Shell found!");

	auto shellElfHeader = cast(Elf64Header*) shellElfModule.start;
	auto shellContext = Process(shellElfHeader);

	shellContext.start();
}