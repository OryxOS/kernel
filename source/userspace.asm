global userMain

section .user_text

userMain:
	mov r10, 0
	mov rdi, helloStr
	o64 syscall

	jmp $

helloStr:
	db "Hello from userspace"