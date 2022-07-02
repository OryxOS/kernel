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
	extern syscallYeild
	dq syscallYeild
	extern syscallPutChr
	dq syscallPutChr

section .text

initSyscalls:
	; Enable `syscall` and `sysret`
	mov rcx, 0xC0000082 
	wrmsr               
	mov rcx, 0xC0000080 
	rdmsr               
	or eax, 1           
	wrmsr               
	mov rcx, 0xC0000081 
	rdmsr               
	mov edx, 0x00180008 
	wrmsr               

	; Set the KernelGSBase MSR to point to the Stack Info struct
	mov rcx, 0xC0000102;
	mov rdx, stackInfo
	shr rdx, 32
	mov rax, stackInfo
	wrmsr

	; Set the syscall handler		
	mov rcx, 0xc0000082
	mov rdx, syscallHandler
	shr rdx, 32
	mov rax, syscallHandler
	wrmsr
	ret


syscallHandler:
	swapgs
	mov gs:8, rsp ; Save user stack
	mov rsp, gs:0 ; Switch to kernel stack

 	push rcx

	; Check if syscall is `yield`
	cmp R10, 0
	je yieldSyscall
	jne normalSyscall

	yieldSyscall:
	mov rdi, rcx  ; Save process execution point
	mov rsi, gs:8 ; Save process stack address

	normalSyscall:
    lea rbx, [rel syscallTable]
    call [rbx + r10 * 8]

	pop rcx

	mov gs:0, rsp   ; Save kernel stack
	mov rsp, [gs:8] ; Switch to user stack
	swapgs

	o64 sysret
