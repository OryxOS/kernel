

/* Tell the linker that we want the symbol _start to be our entry point */
ENTRY(main)
 
SECTIONS
{
    . = 0xffffffff80200000;

    .stivale2hdr : {
        KEEP(*(.stivale2hdr))
    }
 
    .text : {
        *(.text*)
    }
 
    .rodata : {
        *(.rodata*)
    }
 
    .data : {
        *(.data*)
    }
 
    .bss : {
        *(COMMON)
        *(.bss*)
    }
}