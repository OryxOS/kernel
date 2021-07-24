global initSyscalls
global stackInfo

section .data

; There will always be 2 stacks in use, the kernel 
; stack and the current process's stack. Whenever a
; process is switched to, this structs values must be updated
; these can easily be accesses through `swapgs`
stackInfo:
	dq 0 ; Kernel Stack
	dq 0 ; User stack

align 16
syscallTable:
	extern syscallPutStr
	dq syscallPutStr

section .text

initSyscalls:
	; Enable `syscall` and `sysret`
	mov RCX, 0xC0000082 
	wrmsr               
	mov RCX, 0xC0000080 
	rdmsr               
	or EAX, 1           
	wrmsr               
	mov RCX, 0xC0000081 
	rdmsr               
	mov EDX, 0x00180008 
	wrmsr               

	; Set the KernelGSBase MSR to point to the Stack Info struct
	mov rcx, 0xC0000102;
	mov rdx, stackInfo
	shr rdx, 32
	mov rax, stackInfo
	wrmsr

	; Set the syscall handler		
	mov RCX, 0xc0000082
	mov RDX, syscallHandler
	shr RDX, 32
	mov RAX, syscallHandler
	wrmsr
	ret

syscallHandler:
	swapgs
	mov gs:8, rsp ; Save user stack
	mov rsp, gs:0 ; Switch to kernel stack

	push rax
 	push rbx
 	push rcx
 	push rdx
 	push rbp
 	push rsi
 	push rdi
 	push r8
 	push r9
 	push r10
 	push r11
 	push r12
 	push r13
	push r14
	push r15

    lea rbx, [rel syscallTable]
    call [rbx + r10 * 8]

	pop r15
	pop r14
	pop r13
	pop r12
	pop r11
	pop r10
	pop r9
	pop r8
	pop rdi
	pop rsi
	pop rbp
	pop rdx
	pop rcx
	pop rbx
	pop rax

	mov gs:0, rsp   ; Save kernel stack
	mov rsp, [gs:8] ; Switch to user stack
	swapgs

	o64 sysret