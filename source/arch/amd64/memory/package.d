module arch.amd64.memory;

/* OryxOS Low-Level Memory Management (Amd64)
 * This is the root file of the amd64 memory-management module
 * It contains the global init method and other stuff that
 * both the pmm and vmm need.
 */

enum PageSize = 0x1000;                  // Standard x86 page size (4kb)

enum PhysOffset = 0xFFFF800000000000;    // Oryx is a higherhalf kernel (PML4:256)
enum KernelBase = 0xFFFFFFFF80000000;    // Set by Stivale spec

// Useful for clearing up return types
alias VirtAddress = void*;
alias PhysAddress = void*;