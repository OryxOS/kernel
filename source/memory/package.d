module memory;

// Arch-independant constants
enum PhysOffset = 0xFFFF800000000000;    // Oryx is a higher half kernel (>PML4:256)
enum KernelBase = 0xFFFFFFFF80000000;    // Set by the lord himself