section .stivale2hdr

header:
	dq 0			; Entry point - 0 for linkr-Entry
	dq stack.top	; Stack address
	dq 0
	dq 0

section .bss

align 16
stack:
	resb 32768
.top: