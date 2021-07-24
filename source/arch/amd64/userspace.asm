extern stackInfo
global jumpUserSpace

section .text

; RDI - function address
; RSI - stack top address
jumpUserSpace:
	; Store stack info
	mov [stackInfo], rsp
	mov [stackInfo + 8], rsi

	mov rcx, rdi       ; Load fuction into RIP
	mov rsp, rsi       ; Load stack
	mov r11, 0x202     ; Load rflags register
	o64 sysret