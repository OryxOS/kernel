module arch.amd64.drivers.legacy.keyboard;

// Legacy PS2 keyboard support

import arch.amd64.pic : endInterrupt;
import arch.amd64.cpu : readByte;

// Event buffer
private __gshared char curEvent;

// Keyboard status
private __gshared bool capsLockActive;
private __gshared bool shiftActive;
private __gshared bool ctrlActive;
private __gshared bool altActive;

private shared bool doubleScanCode;

// Important scancodes

private enum capsLockPress     = 0x3A;

private enum leftAltPress      = 0x38;
private enum leftAltRelease    = 0xB8;

private enum leftShiftPress    = 0x2A;
private enum leftShiftRelease  = 0xAA;

private enum leftCtrlPress     = 0x1D;
private enum leftCtrlRelease   = 0x9D;

/// Returns a char if a key event occured
/// Returns
/// 	null          = no even has occured
/// 	normal char   = result of the event
char getKeyEvent() {
	// Save and clear buffer
	immutable char ret = curEvent;
	curEvent = '\0';

	return ret;
}

private immutable char[] shiftcapsLockMappings = [
    '\0', '\033', '!', '@', '#', '$', '%', '^', '&', '*', '(', ')', '_', '+', '\b',
    '\t', 'q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p', '{', '}', '\n',
    '\0', 'a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l', ':', '"', '~', '\0', '|',
    'z', 'x', 'c', 'v', 'b', 'n', 'm', '<', '>', '?', '\0', '\0', '\0', ' '
];

private immutable char[] capsLockMappings = [
	'\0', '\033', '1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '-', '=', '\b',
	'\t', 'Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P', '[', ']', '\n',
	'\0', 'A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L', ';', '\'', '`', '\0',
	'\\', 'Z', 'X', 'C', 'V', 'B', 'N', 'M', ',', '.', '/', '\0', '\0', '\0', ' '
];

private immutable char[] shiftMappings = [
	'\0', '\033', '!', '@', '#', '$', '%', '^', '&', '*', '(', ')', '_', '+', '\b',
	'\t', 'Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P', '{', '}', '\n',
	'\0', 'A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L', ':', '"', '~', '\0', '|',
	'Z', 'X', 'C', 'V', 'B', 'N', 'M', '<', '>', '?', '\0', '\0', '\0', ' '
];

private immutable char[] normalMappings = [
	'\0', '\033', '1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '-', '=', '\b',
	'\t', 'q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p', '[', ']', '\n',
	'\0', 'a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l', ';', '\'', '`', '\0', '\\',
	'z', 'x', 'c', 'v', 'b', 'n', 'm', ',', '.', '/', '\0', '\0', '\0', ' '
];


private extern (C) void handler() {
	immutable ubyte input = readByte(0x60);

	// Special keys
	switch (input) {
		case capsLockPress:    capsLockActive = !capsLockActive; return;
		case leftAltPress:     altActive      = true;            return;
		case leftAltRelease:   altActive      = false;           return;
		case leftShiftPress:   shiftActive    = true;            return;
		case leftShiftRelease: shiftActive    = false;           return;
		case leftCtrlPress:    ctrlActive     = true;            return;
		case leftCtrlRelease:  ctrlActive     = false;           return;
		default:                                                 break;
	}

	if (input > 57)
		return;

	// Update the event buffer

	if (capsLockActive && shiftActive)
		curEvent = shiftcapsLockMappings[input];

	if (shiftActive) 
		curEvent = shiftMappings[input];
	
	if (capsLockActive)
		curEvent = capsLockMappings[input];

	if (!capsLockActive && !shiftActive)
		curEvent = normalMappings[input];

}

extern (C) void keyboardHandler() {
	asm {
		naked              ;

		push RAX           ;
		push RBX           ;
		push RCX           ;
		push RDX           ;
		push RSI           ;
		push RDI           ;
		push RBP           ;
		push R8            ;
		push R9            ;
		push R10           ;
		push R11           ;
		push R12           ;
		push R13           ;
		push R14           ;
		push R15           ;

		call handler       ;

		mov RDI, 33        ;
		call endInterrupt  ;

		pop R15            ;
		pop R14            ;
		pop R13            ;
		pop R12            ;
		pop R11            ;
		pop R10            ;
		pop R9             ;
		pop R8             ;
		pop RBP            ;
		pop RDI            ;
		pop RSI            ;
		pop RDX            ;
		pop RCX            ;
		pop RBX            ;
		pop RAX            ;
		
		iretq              ; 
	}
}