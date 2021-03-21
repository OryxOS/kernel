module arch.amd64.memory;

/* OryxOS Low-Level Memory Management (Amd64)
 * This is the root file of the amd64 memory-management module
 * It contains the global init method and other stuff that
 * both the pmm and vmm need.
 */

enum PageSize = 0x1000;