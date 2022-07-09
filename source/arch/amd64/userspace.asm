extern StackInfo

global init_userspace
global load_userspace

section .text

; Loads the init process into userspace
; RDI - init's main function
; RSI - stack
; 
init_userspace:
	; Store stack info
	mov [StackInfo], rsp
	mov [StackInfo + 8], rsi

	mov rcx, rdi ; Intruction address to be loaded in RIP
	mov rsp, rsi ; Load stack

	mov r11, 0x202 ; Load rflags register
	
	o64 sysret

load_userspace:
	; Store stack info
	mov [StackInfo], rsp
	mov [StackInfo + 8], rsi
	mov rcx, rdi ; Intruction address to be loaded in RIP
	
	mov r11, 0x202 ; Load rflags register
	mov r10, 0x202;
	mov gs:0, rsp   ; Save kernel stack
	mov rsp, [gs:8] ; Switch to user stack
	
	swapgs
	o64 sysret