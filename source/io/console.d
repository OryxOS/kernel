module io.console;

import io.framebuffer;
import core.atomic;

/* OryxOS Console implementation
 * This is a very simple console design. It works
 * by directly putting stuff on the screen
 */

enum Color: pixel {
	Background = 0x0D1117,
	Normal     = 0xC9D1D9,
	HighLight1 = 0xFF7B72,
	HighLight2 = 0x79C0FF,
	HighLight3 = 0xFFA775,
}

// Control Structure
private struct Console {
	uint posX; 
	uint posY;

	uint maxX;
	uint maxY;

	this(FrameBufferInfo fb) {
		this.maxX = fb.width;
		this.maxY = fb.height;
	}
}

private shared Console console;

void initConsole() {
	console = Console(getFrameBufferInfo());

	plotScreen(Color.Background);
}

void putChr(const char c, Color col = Color.Normal) {
	// End of line
	if(console.posX > console.maxX) {
		atomicOp!"+="(console.posY, 16);
		console.posX = 0;
	}

	// Scroll
	if(console.posY > console.maxY) {
		scrollScreen(16);
		plotRect(Color.Background, 0, console.maxY - 16, console.maxX, 16);
		console.posY = console.maxY - 16;
	}

	// Handle newlines
	switch(c) {
		case '\n':
			atomicOp!"+="(console.posY, 16);
			console.posX = 0;
			break;

	default:
			plotChr(col, Color.Background, c, console.posX, console.posY);
			atomicOp!"+="(console.posX, 8);
			break;
	}
}

void putStr(const string s, Color col = Color.Normal) {
	foreach (c; s) {
		putChr(c, col);
	}
}

//////////////////////////////
//    Variadic Printing     //
//////////////////////////////


void write(T...)(T args) {
	foreach (i; args) {
		putItem(i);
	}
}
void writeln(T...)(T args) {
	write(args, '\n');
}

// Char
private void putItem(char item) {
	putChr(item);
}

// Bool
private void putItem(bool item) {
	if (item == true) {
		putStr("true", Color.HighLight1);

	} else {
		putStr("false", Color.HighLight1);
	}
}

// String
private void putItem(string item) {
	putStr(item);
}

// Ushort
void putItem(ushort item) {
	printDecNum(cast(size_t)(item));
}

// Uint
void putItem(uint item) {
	printDecNum(cast(size_t)(item));
}

// Size_t
void putItem(size_t item) { 
	printDecNum(item);
}

// Byte
void putItem(byte item) {
	// Sign fix
	if(item < 0) {
		putStr("-", Color.HighLight1);
		printDecNum(-cast(size_t)(item));
	} else {
		printDecNum(item);
	}
}

// Short
void putItem(short item) {
	// Sign fix
	if(item < 0) {
		putStr("-");
		printDecNum(-cast(size_t)(item));
	} else {
		printDecNum(item);
	}
}

// Int
void putItem(int item) {
	// Sign fix
	if(item < 0) {
		putStr("-");
		printDecNum(-cast(size_t)(item));
	} else {
		printDecNum(item);
	}
}

//////////////////////////////
//          Logging         //
//////////////////////////////

enum LogLevel {
	Info,
	Warning,
	Error,
}

private enum IndentCount = 4; // Size of a tab

void log(T...)(LogLevel level, uint indent, T args) {
	// Indent to the right level
	foreach (i; 0..indent * IndentCount) {
		putChr(' ');
	}

	putChr('[');

	// + - ! Levels
	switch (level) {
	case LogLevel.Info:
		putChr('+', Color.HighLight2);
		break;
	case LogLevel.Warning:
        putChr('-', Color.HighLight3);
        break;
	case LogLevel.Error:
        putChr('!', Color.HighLight1);
        break;
	default:
		assert(0); // Not possible	
	}

	putStr("] ");

	// Print message
	write(args, '\n');
}

//////////////////////////////
//        Formatting        //
//////////////////////////////

private immutable TABLE_B16 = "0123456789abcdef";
private immutable TABLE_B10 = "0123456789";

// Integer to Hexadecimal conversion
private void printHexNum(size_t item) {
	char[16] buf;

	if (item == 0) {
		putStr("0x0", Color.HighLight1);
	}

	putStr("0x", Color.HighLight2);
	for (int i = 15; item; i--) {
		buf[i] = TABLE_B16[item % 16];
		item /= 16;
	}

	foreach(c; buf) {
		// Don't print unused whitespace
		if (c != char.init) {
			putChr(c, Color.HighLight1);
		}
	}
}
private void printDecNum(size_t item) {
	char[32] buf;

	if (item == 0) {
		putStr("0", Color.HighLight1);
	}

	for (int i = 31; item; i--) {
		buf[i] = TABLE_B10[item % 10];
		item /= 10;
	}

	foreach(c; buf) {
		// Don't print unused whitespace
		if (c != char.init) {
			putChr(c, Color.HighLight1);
		}
	}
} 