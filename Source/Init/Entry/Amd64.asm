global _start

extern Main
extern RunConstructors

section .text
_start:
	call RunConstructors
	call Main