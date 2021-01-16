extern "C" void kmain() {
    char* vmem = (char*)0xB000;
    *vmem = 'h';
}
