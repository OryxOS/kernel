module scheduler.queue;

import au.types;

import lib.collections;

import scheduler.thread;

import io.console;

struct Queue {
	LinkedList!(Thread) threads;
	usize index;
	ubyte selections;

	void start_next() {
	// Bump index or return to queue start
	if (index == threads.get_length() - 1)
		index = 0;
	else
		index++;
	
	selections--;

	threads[index].start();
	}

	void add_thread(Thread t) {
		threads.append(t);
	}

	void remove_thread(Thread t) {
		for (usize i = 0; i < threads.get_length(); i++) {
			if (threads[i].id == t.id) {
				threads.remove(i);
			}
		}
	}

	void save_process(void* ins_ptr, void* stack) {
		threads[index].ins_ptr = ins_ptr;
		threads[index].stack = stack;
	}

	bool is_empty() {
		return threads.get_length() == 0 ? true : false;
	}
}