module scheduler;

import au.elf;
import au.math;
import au.types;
import au.string;

import lib.limine;
import lib.collections;

import io.console;

import memory;
import memory.physical;

import scheduler.queue;
import scheduler.thread;
import scheduler.process;

version (X86_64) import arch.amd64.memory;

// Location: arch/amd64/userspace.asm
private extern extern (C) void init_userspace(void* start, void* stack);

//////////////////////////////
//         Instance         //
//////////////////////////////

private static immutable ubyte[3] PrioritySelections = [3, 2, 1];

private __gshared LinkedList!(Process) processes;
private __gshared Queue[3] queues; // High, standard and low priority queues
private __gshared usize index;     // Index of the last queue threads were selected from

void init_shed(ModuleResponse* mods) {
	writefln("\nInitialising scheduler:");

	// Setup queues;
    queues[0].selections = PrioritySelections[0];
	queues[1].selections = PrioritySelections[1];
	queues[2].selections = PrioritySelections[2];

	log(1, "Registered %d thread queues", queues.length);

	// Load all application modules
	log(1, "Copying %d applications into new memory", mods.count);
	for (usize i = 0; i < mods.count; i++) {
		/* Unfortunately limine doesn't guarentee alignment or overlap prevention on
		 * modules, which can be an issue when applications are freed so we have to
		 * move all modules to new memory;
		 */

		// Determine the size of the module file in pages
		auto p_size = div_round_up( mods.modules[i].size, PageSize);
		auto blocks = new_block(p_size);
		
		// Copy to new memory
		void* new_addr = blocks.unwrap_result("Could not allocate memory for app modules") + PhysOffset;
		new_addr[0..mods.modules[i].size] = mods.modules[i].address[0..mods.modules[i].size];

		processes.append(Process(cast(Elf64Header*) new_addr));

		/* FIXME: For some reason `&this` doesn't return the address of an instance of a struct
		 * so it is necessary to set the parent of each thread outside of the Process 
		 * constructor
		 */
		processes[i].threads[0].parent = &processes[i];

		queues[0].add_thread(processes[i].threads[0]);
	}

	// Start process: 0:0
	processes[0].p_map.set_active();
	queues[0].selections--;
	index = 0;

	log(1, "Scheduler initialised");

	init_userspace(queues[0].threads[0].ins_ptr, queues[0].threads[0].stack);
}

private void start_next_thread() {
	// Update index
	if (queues[index].selections == 0) {
		queues[index].selections = PrioritySelections[index];

		// Find next non-empty queue
		while(index <= queues.length - 1) {
			if (index == queues.length - 1)
				index = 0;
			else
				index++;

			if (queues[index].threads.get_length() > 0)
				break;
		}
	}

	queues[index].start_next();	
}

//////////////////////////////
//         Syscalls         //
//////////////////////////////

/// Switch execution from one thread to another
extern (C) void sys_yield(void* ins_ptr, void* stack) {
	queues[index].save_process(ins_ptr, stack);

	start_next_thread();
}

/// Closes a process
extern (C) void sys_exit() {
	// Switch to kernel's pagemap as the process's is going to be deleted
	kernel_pm.set_active();

	auto parent = queues[index].threads[queues[index].index].parent;

	parent.p_map.del_all_tables();
	
	// Remove all threads belonging to the process
	foreach (t; parent.threads) {
		// Delete thread's stack and remove from queues
		del_block(t.stack - PageSize, 1);

		queues[index].remove_thread(t);
	}

	// Remove process from the processes list
	foreach (i; 0..processes.get_length - 1) {
		if (processes[i].id == parent.id) {
			processes.remove(i);
		}
	}

	start_next_thread();
}