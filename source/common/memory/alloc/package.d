module common.memory.alloc;

import common.memory.alloc.block;

struct Dumbass {
	int a;
	int b;
	int c;
}

void initAlloc() {
	initBlockAlloc();

	foreach(i; 0..4096000) {
		newBlockAlloc(512);
	}
}