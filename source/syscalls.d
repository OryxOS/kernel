module syscalls;

/* OryxOS System Calls
 * these are all the syscalls that OryxOS provides
 * to userspace
 */

extern (C) void syscallPutStr(char* str) {
    import lib.util.console : putStr;
    import lib.util.string : fromCString;

    putStr(fromCString(str), 0x000000);
}