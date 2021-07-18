module lib.util.types;

/* Types Module
 * This module contains a bunch of useful type aliases
 * these are useful for clarifications throughout the 
 * whole code base
 */

/// Physical and Virtual memory addresses, Virtual ones should be > than 0xFFFF800000000000
alias VirtAddress = void*;
alias PhysAddress = void*;

/// Framebuffer pixel
alias pixel = uint;

/// Largest per-arch integer
version (X86_64) {
    alias usize = ulong;
    alias isize = long;
}

