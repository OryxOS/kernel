module common.memory;

// Useful for clearing up return types
alias VirtAddress = void*;
alias PhysAddress = void*;

// Arch-independant constants
enum PhysOffset = 0xFFFF800000000000;    // Oryx is a higher half kernel (>PML4:256)
enum KernelBase = 0xFFFFFFFF80000000;    // Set by Stivale spec