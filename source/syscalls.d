module syscalls;

/* OryxOS System Calls
 * These are all the syscalls that OryxOS provides
 * to userspace
 */


/// Prints a character onto the console
extern (C) void syscallPutChr(char chr, uint col) {
    import io.console : putChr;

    putChr(chr, col);
}

