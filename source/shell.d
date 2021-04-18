module shell;

/* OryxOS Kernel Shell
 * This is just a simple shell in ring 0 that is nice for demoing the kernel
 */

import lib.std.stdio;
import lib.std.string;

import io.framebuffer;
import common.memory.physical;

import arch.amd64.drivers.legacy.keyboard; //TODO: Keyboard HAL

// Command buffer - null terminated
private __gshared char[64] cmdBuffer = '\0';
private __gshared size_t   bufferPos;

void shellMain() {
	clearConsole();

	writefln("OryxOS in-kernel shell");
	
	putStr("\n\n");
	putPromt();

	showCursor(true);

	while(1) {
		asm { hlt; }
		immutable auto event = getKeyEvent();

		if (event == '\0')
			continue;

		switch (event) {
		case '\n':
			putChr('\n');
			
			handleCommand(fromCString(&cmdBuffer[0]));

			putPromt();
			cmdBuffer = '\0';
			bufferPos = 0;
			break;

		case '\b':
		if (bufferPos != 0) {
			putChr('\b');
			cmdBuffer[bufferPos--] = '\0';
		}
			break;

		default:
			cmdBuffer[bufferPos++] = event;
			putChr(event);
			break;
		}
	}
}

private void handleCommand(string command) {
	switch (command) {
	case "help":
		writefln("Commands:
		help         - show this dialog
		clear        - clear the screen
		info         - basic info about OryxOS\nTests:
		test-scroll  - scroll through 100 lines
		test-panic   - display the panic screen (Fatal)
		test-int     - calls interrupt 3 (Fatal)
		test-pmm     - allocate a 4kb block of memory");
		break;

	case "clear":
		clearConsole();
		break;
	
	case "info":
		writefln("OryxOS version 0.0.0 (Amd64)");
		break;

	case "test-scroll":
		foreach(i; 0..100)
			writefln("%d", i);
		break;

	case "test-panic":
		showCursor(false);
		panic("Console called panic");
		break;

	case "test-int":
		showCursor(false);
		asm {
			int 3;
		}
		break;
	
	case "test-pmm":
		PmmResult test = newBlock(1);
		if (test.isOkay) {
			writefln("Block allocated: %h", cast(ulong)(test.unwrapResult()));
		} else {
			writefln("Allocation failed: %d", test.unwrapError());
		}
		break;

	default:
		writefln("Error, command \"%s\" is not valid", command);
		return;
	}
}

private void putPromt() {
	putChr('[');
	putStr("Demo", Color.HighLight2);
	putStr("@OryxOS] > ");
}