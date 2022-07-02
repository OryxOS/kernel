module syscalls;

/* OryxOS System Calls
 * These are all the syscalls that OryxOS provides
 * to userspace
 */

import au.types;

/// Yeilds CPU control to the next proccess
extern (C) void syscallYeild(VirtAddress execPoint, VirtAddress stack) {
    import scheduler : switchNext;

    switchNext(execPoint, stack); 
}

/// Prints a character onto the console
extern (C) void syscallPutChr(char chr, uint col) {
    import io.console : putChr;

    putChr(chr, col);
}