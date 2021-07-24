ENTRY(main)
 
SECTIONS
{
	. = 0xFFFFFFFF80200000;

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
	
	. = 0x2000000;

	.user_text : {
		*(.user_text*)
	}
}