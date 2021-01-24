using ConPtr = void (*)();

extern "C" ConPtr __init_array_start[];
extern "C" ConPtr __init_array_end[];

extern "C" void RunConstructors() {
	for(ConPtr *c = __init_array_start; c != __init_array_end; c++) {
		(*c)();
	}
}
