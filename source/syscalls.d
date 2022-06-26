module syscalls;

/* OryxOS System Calls
 * These are all the syscalls that OryxOS provides
 * to userspace
 */

extern (C) void syscallPutChr(char chr, uint col) {
    import io.console : putChr;

    putChr(chr, col);
}