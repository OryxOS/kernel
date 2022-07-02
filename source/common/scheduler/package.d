module common.scheduler;

import lib.elf;
import lib.limine;
import au.math; 
import au.types;
import au.string;
import io.console;

import common.memory;
import common.memory.heap;
import common.memory.physical;

version (X86_64) import arch.amd64.memory;

extern extern (C) void jumpUserSpace(VirtAddress start, VirtAddress stack);
extern extern (C) void returnUserSpace(VirtAddress start, VirtAddress stack);

struct Process {
	AddressSpace addressSpace;
	VirtAddress  stack;
	VirtAddress  execPoint;


	// Creates a new userspace context from an ELF file
	this(Elf64Header* header) {
		this.addressSpace = AddressSpace(newBlock()
		                                 .unwrapResult("Not enough space for process's PML Tables"));

		usize stackBottom = cast(usize) newBlock().unwrapResult("Not enough space for stack");

		this.stack = cast(VirtAddress) stackBottom + PageSize;
		this.execPoint = cast(VirtAddress) header.entry;

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
								  EntryFlags.Present | EntryFlags.Writeable | EntryFlags.UserAccessable);
				}
			}
		}
	}

	// Only used when doing a fresh jump to userspace
	void start() {
		this.addressSpace.setActive();
		jumpUserSpace(this.execPoint, this.stack);
	}

	// Used in yield syscall
	void switchTo() {
		this.addressSpace.setActive();
		returnUserSpace(this.execPoint, this.stack);
	}
}

//////////////////////////////
//         Instance         //
//////////////////////////////

private __gshared LinkedList!(Process) processes = LinkedList!(Process)();
private __gshared ulong currentPID;

void initScheduler(ModuleResponse* limineModules) {

	LimineFile* yesModule = limineModules.getModule("/applications/yes.elf");
	LimineFile* noModule = limineModules.getModule("/applications/no.elf");

	if (yesModule == null || noModule == null)
		panic("No yes or no found!");

	processes.append(Process(cast(Elf64Header*) yesModule.address));
	processes.append(Process(cast(Elf64Header*) noModule.address));

	writefln("Yes entrypoint: %h", processes[0].execPoint);
	writefln("No entrypoint: %h", processes[1].execPoint);

	processes[0].start();

	currentPID = 0;
}

// TODO: priorities
extern (C) void syscallYeild(VirtAddress execPoint, VirtAddress stack) {
	processes[currentPID].execPoint = execPoint;
	processes[currentPID].stack = stack;

	if (currentPID == processes.getLength() - 1)
		currentPID = 0;
	else
		currentPID++;
	
	processes[currentPID].switchTo();
}