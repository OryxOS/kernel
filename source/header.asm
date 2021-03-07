section .stivale2hdr

header:
	dq 0			; Entry point - 0 for linkr-Entry
	dq stack.top	; Stack address
	dq 0
	dq framebufferTag;

section .data

framebufferTag:
	dq 0x3ecc1bc43d0f7971
	dq 0
	dw 0
	dw 0
	dw 0	

section .bss

align 16
stack:
	resb 32768
.top:
