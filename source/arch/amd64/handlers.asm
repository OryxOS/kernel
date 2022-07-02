; Interrupt stubs

extern exceptionHandler;

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
	call exceptionHandler

	push r15
	push r14
	push r13
	push r12
	push r11
	push r10
	push r9
	push r8
	push rdi
	push rsi
	push rbp
	push rdx
	push rcx
	push rbx
	push rax

	add rsp, 16
	iret
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
	call exceptionHandler
	push r15
	push r14
	push r13
	push r12
	push r11
	push r10
	push r9
	push r8
	push rdi
	push rsi
	push rbp
	push rdx
	push rcx
	push rbx
	push rax
	add rsp, 16
	iret
%endmacro

section .text

global divZeroHandler
divZeroHandler:
	handler 0

global debugHandler
debugHandler:
	handler 1

global nmiHandler
nmiHandler:
	handler 2

global breakpointHandler
breakpointHandler:
	handler 3

global overflowHandler
overflowHandler:
	handler 4

global boundRangeHandler
boundRangeHandler:
	handler 5

global invOpcodeHandler
invOpcodeHandler:
	handler 6

global noDeviceHandler
noDeviceHandler:
	handler 7

global doubleFaultHandler
doubleFaultHandler:
	handlerWithErrorCode 8

global invTssHandler
invTssHandler:
	handlerWithErrorCode 10

global segNotPresentHandler
segNotPresentHandler:
	handlerWithErrorCode 11

global ssFaultHandler
ssFaultHandler:
	handlerWithErrorCode 12

global gpfHandler
gpfHandler:
	handlerWithErrorCode 13

global pageFaultHandler
pageFaultHandler:
	handlerWithErrorCode 14

global fpuFaultHandler
fpuFaultHandler:
	handler 16

global alignCheckHandler
alignCheckHandler:
	handlerWithErrorCode 17

global machineCheckHandler
machineCheckHandler:
	handlerWithErrorCode 18

global simdFaultHandler
simdFaultHandler:
	handler 19

global virtFaultHandler
virtFaultHandler:
	handler 20

global secFaultHandler
secFaultHandler:
	handler 30
