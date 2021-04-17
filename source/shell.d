module shell;

/* OryxOS Kernel Shell
 * This is just a simple shell in ring 0 that is nice for demoing the kernel
 */

import lib.std.stdio;

import arch.amd64.drivers.legacy.keyboard;

void shellMain() {
    clearConsole();

    writefln("OryxOS in-kernel shell");

    while(1) {
        asm { hlt; }
        immutable auto event = getKeyEvent();

        if (event != char.init)
            writef("%c", event);
    }
}