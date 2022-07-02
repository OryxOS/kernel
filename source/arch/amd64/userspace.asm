extern stackInfo

global jumpUserSpace
global returnUserSpace

section .text

; RDI - function address
; RSI - stack top address
jumpUserSpace:
	; Store stack info
	mov [stackInfo], rsp
	mov [stackInfo + 8], rsi

	mov rcx, rdi       ; Intruction address to be loaded in RIP
	mov rsp, rsi       ; Load stack
	mov r11, 0x202     ; Load rflags register
	o64 sysret

returnUserSpace:
	; Store stack info
	mov [stackInfo], rsp
	mov [stackInfo + 8], rsi

	mov rcx, rdi ; Intruction address to be loaded in RIP
	
	mov gs:0, rsp   ; Save kernel stack
	mov rsp, [gs:8] ; Switch to user stack
	swapgs

	o64 sysret