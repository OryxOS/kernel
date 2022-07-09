module arch.amd64.drivers.legacy.keyboard;

// Legacy PS2 keyboard support

import io.console;

import arch.amd64.apic : end_interrupt;
import arch.amd64.cpu  : read_byte;

// Event buffer
private __gshared char event;

// Keyboard status
private __gshared bool capslock_active;
private __gshared bool shift_active;
private __gshared bool ctrl_active;
private __gshared bool alt_active;

private shared bool doubleScanCode;

// Important scancodes

private enum CapslockPress     = 0x3A;

private enum LeftAltPress      = 0x38;
private enum LeftAltRelease    = 0xB8;

private enum LeftShiftPress    = 0x2A;
private enum LeftShiftRelease  = 0xAA;

private enum LeftCtrlPress     = 0x1D;
private enum LeftCtrlRelease   = 0x9D;

private immutable char[] ShiftCapslockMappings = [
    '\0', '\033', '!', '@', '#', '$', '%', '^', '&', '*', '(', ')', '_', '+', '\b',
    '\t', 'q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p', '{', '}', '\n',
    '\0', 'a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l', ':', '"', '~', '\0', '|',
    'z', 'x', 'c', 'v', 'b', 'n', 'm', '<', '>', '?', '\0', '\0', '\0', ' '
];

private immutable char[] CapslockMappings = [
	'\0', '\033', '1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '-', '=', '\b',
	'\t', 'Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P', '[', ']', '\n',
	'\0', 'A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L', ';', '\'', '`', '\0',
	'\\', 'Z', 'X', 'C', 'V', 'B', 'N', 'M', ',', '.', '/', '\0', '\0', '\0', ' '
];

private immutable char[] ShiftMappings = [
	'\0', '\033', '!', '@', '#', '$', '%', '^', '&', '*', '(', ')', '_', '+', '\b',
	'\t', 'Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P', '{', '}', '\n',
	'\0', 'A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L', ':', '"', '~', '\0', '|',
	'Z', 'X', 'C', 'V', 'B', 'N', 'M', '<', '>', '?', '\0', '\0', '\0', ' '
];

private immutable char[] NormalMappings = [
	'\0', '\033', '1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '-', '=', '\b',
	'\t', 'q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p', '[', ']', '\n',
	'\0', 'a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l', ';', '\'', '`', '\0', '\\',
	'z', 'x', 'c', 'v', 'b', 'n', 'm', ',', '.', '/', '\0', '\0', '\0', ' '
];


private extern (C) void handler() {
	immutable ubyte input = read_byte(0x60);

	// Special keys
	switch (input) {
		case CapslockPress:    capslock_active = !capslock_active; return;
		case LeftAltPress:     alt_active      = true;             return;
		case LeftAltRelease:   alt_active      = false;            return;
		case LeftShiftPress:   shift_active    = true;             return;
		case LeftShiftRelease: shift_active    = false;            return;
		case LeftCtrlPress:    ctrl_active     = true;             return;
		case LeftCtrlRelease:  ctrl_active     = false;            return;
		default:                                                   break;
	}

	if (input == 35 && ctrl_active) {
		writefln("Halt command triggered! System has been placed in an endless loop");
		while(1) {}
	}

	if (input > 57)
		return;

	// Update the event buffer

	if (capslock_active && shift_active)
		event = ShiftCapslockMappings[input];

	if (shift_active) 
		event = ShiftMappings[input];
	
	if (capslock_active)
		event = CapslockMappings[input];

	if (!capslock_active && !shift_active)
		event = NormalMappings[input];

}

extern (C) void kbd_handler() {
	asm {
		naked ;

		push RAX ;
		push RBX ;
		push RCX ;
		push RDX ;
		push RSI ;
		push RDI ;
		push RBP ;
		push R8  ;
		push R9  ;
		push R10 ;
		push R11 ;
		push R12 ;
		push R13 ;
		push R14 ;
		push R15 ;

		call handler       ;
		call end_interrupt ;

		pop R15 ;
		pop R14 ;
		pop R13 ;
		pop R12 ;
		pop R11 ;
		pop R10 ;
		pop R9  ;
		pop R8  ;
		pop RBP ;
		pop RDI ;
		pop RSI ;
		pop RDX ;
		pop RCX ;
		pop RBX ;
		pop RAX ;

		iretq ; 
	}
}

//////////////////////////////
//         Syscalls         //
//////////////////////////////

extern (C) char sys_get_keystroke() {
	// Save and clear buffer
	immutable char ret = event;
	event = '\0';

	return ret;
}