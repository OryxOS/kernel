; Interrupt stubs

extern exception_handler;

%macro handler 1
	; Interrupt frame already on the stack
	push 0 ; Error code
	push %1
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

	mov rdi, rsp
	call exception_handler

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

	add rsp, 16
	iretq
%endmacro

%macro handlerWithErrorCode 1
	; Interrupt frame already on the stack
	push %1
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

	mov rdi, rsp
	call exception_handler

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

	;add rsp, 16
	iretq
%endmacro

section .text

global div_zero_handler
div_zero_handler:
	handler 0

global debug_handler
debug_handler:
	handler 1

global nmi_handler
nmi_handler:
	handler 2

global breakpoint_handler
breakpoint_handler:
	handler 3

global overflow_handler
overflow_handler:
	handler 4

global bound_range_handler
bound_range_handler:
	handler 5

global invalid_op_handler
invalid_op_handler:
	handler 6

global no_device_handler
no_device_handler:
	handler 7

global double_fault_handler
double_fault_handler:
	handlerWithErrorCode 8

global invalid_tss_handler
invalid_tss_handler:
	handlerWithErrorCode 10

global seg_absent_handler
seg_absent_handler:
	handlerWithErrorCode 11

global ss_fault_handler
ss_fault_handler:
	handlerWithErrorCode 12

global gpf_handler
gpf_handler:
	handlerWithErrorCode 13

global page_fault_handler
page_fault_handler:
	handlerWithErrorCode 14

global fpu_fault_handler
fpu_fault_handler:
	handler 16

global align_check_handler
align_check_handler:
	handlerWithErrorCode 17

global machine_check_handler
machine_check_handler:
	handlerWithErrorCode 18

global simd_fault_handler
simd_fault_handler:
	handler 19

global virt_fault_handler
virt_fault_handler:
	handler 20

global sec_fault_handler
sec_fault_handler:
	handler 30
