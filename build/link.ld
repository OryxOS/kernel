ENTRY(main)

/* Section permissions, required for bootloader */
PHDRS
{
    text    PT_LOAD    FLAGS((1 << 0) | (1 << 2)) ; /* Read | Execute */
    rodata  PT_LOAD    FLAGS((1 << 2)) ;            /* Read */
    data    PT_LOAD    FLAGS((1 << 1) | (1 << 2)) ; /* Read | Write */
}

SECTIONS
{
    /* Place kernel in the higher half */
    . = 0xffffffff80000000;

    .text : {
        *(.text .text.*)
    } :text

    . += CONSTANT(MAXPAGESIZE);

    .rodata : {
        *(.rodata .rodata.*)
    } :rodata

    . += CONSTANT(MAXPAGESIZE);

    .data : {
        *(.data .data.*)
    } :data

    .bss : {
        *(COMMON)
        *(.bss .bss.*)
    } :data
}