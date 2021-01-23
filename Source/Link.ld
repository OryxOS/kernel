ENTRY(_start)
 
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

    . = ALIGN(0x1000);

    /* Constructor array */
    .init_array : {
        PROVIDE_HIDDEN (__init_array_start = .);
        KEEP (*(SORT_BY_INIT_PRIORITY(.init_array.*) SORT_BY_INIT_PRIORITY(.ctors.*)))
        KEEP (*(.init_array .ctors))
        PROVIDE_HIDDEN (__init_array_end = .);
    }
 
    .data : {
        *(.data*)
    }
 
    .bss : {
        *(COMMON)
        *(.bss*)
    }
}


