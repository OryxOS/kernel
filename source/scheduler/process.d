module scheduler.process;

import au.elf;
import au.math; 
import au.types;

import lib.collections;

import memory;
import memory.physical;

import scheduler.thread;

version (X86_64) import arch.amd64.memory;

private __gshared usize top_id = 0;

struct Process {
	usize id;
	Pagemap p_map;
	Thread[1] threads;

	this(Elf64Header* elf) {
		// Give this process a unqiue id
		id = top_id++;

		// Allocate memory for page map and main thread's stack
		this.p_map = Pagemap(new_block()
		                     .unwrap_result("Not enough space for process's PML Tables"));
		usize stack_bottom = cast(usize) new_block().unwrap_result("Not enough space for stack");

		// Map kernel and higher half
		auto proc_tables = cast(ulong[512]*) this.p_map.pml4;
		auto kern_tables = cast(ulong[512]*) kernel_pm.pml4;

		(*proc_tables)[256] = (*kern_tables)[256]; // Higher half
		(*proc_tables)[511] = (*kern_tables)[511]; // Kernel

		// Map thread's stack
		this.p_map.map_page(cast(void*) stack_bottom, cast(void*) stack_bottom,
								  EntryFlags.Present | EntryFlags. Writeable | EntryFlags.UserAccessable);

		
		// Load and map all process headers
		auto prog_hdrs = cast(usize) elf + elf.prog_hdr_offset;
		foreach (i; 0..elf.prog_hdr_count) {
			auto hdr = cast(ElfProgramHeader*) (prog_hdrs + i * ElfProgramHeader.sizeof);
			
			if (hdr.type == ElfProgramHeader.Type.Load) {
				// Map the section into the thread's address space
				usize p_start = align_down(cast(usize) elf + hdr.offset - PhysOffset, PageSize);
				usize v_start = align_down(hdr.v_addr, PageSize);
				usize page_count = div_round_up(hdr.m_size, PageSize);

				for (usize j = 0; j < page_count; j++) {
					this.p_map.map_page(cast(void*) (v_start + j * PageSize), cast(void*) (p_start + j * 4096),
								  EntryFlags.Present | EntryFlags.Writeable | EntryFlags.UserAccessable);
				}
			}
		}
		// Setup main thread;
		threads[0] = Thread(cast(void*) elf.entry, cast(void*) (stack_bottom + PageSize));

		// FIXME: originally thread parents were going to be setup here:
		// threads[0].parent = &this;
	}
}