module scheduler.thread;

/* OryxOS Co-operative Scheduler
 * This scheduler implementation makes use of co-operative multitasking
 * with the yield() syscall. Priorities are handled through (3) seperate
 * queues, one for high, standard and low priority threads respectively.
 * Each queue has a member (selections) which defines how many threads
 * are to be selected and run from that queue before threads are
 * selected from the next (lower priority) queue
 */

import au.types;

import memory;
import memory.physical;

import scheduler.process;

// Location: arch/amd64/userspace.asm
private extern extern (C) void load_userspace(void* start, void* stack);

private __gshared usize top_id = 0;

struct Thread {
	usize id;
	void* stack;
	void* ins_ptr;

	Process* parent;

	this(void* entry, void* stack) {
		this.id = top_id++; // Unique ID
		this.stack = stack;
		this.ins_ptr = entry;

	}

	// Switch control over to this thread
	void start() {
		this.parent.p_map.set_active();
		load_userspace(this.ins_ptr, this.stack);
	}
}