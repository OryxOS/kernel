global init_syscalls
global StackInfo

section .data

; There will always be 2 stacks in use, the kernel 
; stack and the current process's stack. Whenever a
; process is switched to, this structs values must be updated
; these can easily be accesses through `swapgs`
StackInfo:
	dq 0 ; Kernel Stack
	dq 0 ; User stack

align 16
SyscallTable:
	extern sys_yield
	dq sys_yield

	extern sys_exit
	dq sys_exit

	extern sys_put_chr
	dq sys_put_chr

	extern sys_clear_console
	dq sys_clear_console

	extern sys_show_cursor
	dq sys_show_cursor;

	extern sys_get_keystroke
	dq sys_get_keystroke

section .text

init_syscalls:
	; Enable `syscall` and `sysret`
	mov rcx, 0xC0000082 
	wrmsr               
	mov rcx, 0xC0000080 
	rdmsr               
	or eax, 1           
	wrmsr               
	mov rcx, 0xC0000081 
	rdmsr               
	mov edx, (0x8) | (0x18 << 16) ; KernelCodeSegmwnt | (Null2Segment << 16)
	wrmsr               

	; Set the KernelGSBase MSR to point to the Stack Info struct
	mov rcx, 0xC0000102;
	mov rdx, StackInfo
	shr rdx, 32
	mov rax, StackInfo
	wrmsr

	; Set the syscall handler		
	mov rcx, 0xc0000082
	mov rdx, syscall_handler
	shr rdx, 32
	mov rax, syscall_handler
	wrmsr
	ret


syscall_handler:
	swapgs
	mov gs:8, rsp ; Save user stack
	mov rsp, gs:0 ; Switch to kernel stack

	; Save RFLAGS and return address
 	push rcx
	push r11

	; Check if syscall is `yield`
	cmp R10, 0
	je yield
	jne normal

	yield:
	mov rdi, rcx  ; Save process execution point
	mov rsi, gs:8 ; Save process stack address

	normal:
    lea rbx, [rel SyscallTable]
    call [rbx + r10 * 8]

	; Restore RFLAGS and return address
	pop r11
	pop rcx

	mov gs:0, rsp   ; Save kernel stack
	mov rsp, [gs:8] ; Switch to user stack
	swapgs

	o64 sysret
