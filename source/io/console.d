module io.console;

import io.framebuffer;
import core.atomic;

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

	case '\t':
		if (console.posX % 32 == 0) {
			atomicOp!"+="(console.posX, 32);			
		} else {
			atomicOp!"+="(console.posX, console.posX % 32);
		}
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

void log(T...)(uint indent, const string fmt, T args) {
	// Indentation
	foreach(_; 0..indent) {
		putChr('\t');
	}

	putChr('[');
	putChr('+', Color.HighLight2);
	putStr("] ");

	writeln(fmt, args);
}

void writeln(T...)(string fmt, T args) {
	write(fmt, args);
	putChr('\n');
}

void write(T...)(const string fmt, T args) {
	uint strPos;

	foreach (arg; args) {
		// look for format specifier
		for (uint i = strPos; i < fmt.length; i++) {
			if (fmt[i] == '%') {
				switch (fmt[i + 1]) {
				case 's':              // String
					putItem(arg, true);
					break;

				case 'l':              // Bool
					putItem(arg, true);			
					break;

				case 'd':              // Decimal
					putItem(arg, true);
					break;

				case 'h':              // Hexadecimal
					putItem(arg, false);
					break;

				default:
					assert(0, "Format specifier expected");
				}
				strPos = i + 2;       // % + Format specifier
				break;
			} else {
				putChr(fmt[i]);
			}
		}
	}

	// Print remainder of string after last format specifier
	for (int i = strPos; i < fmt.length; i++) {
		putChr(fmt[i]);
	}
}

/* The following is boilerplate, but is unfortunately the 
 * best option using BetterC, which doesn't have typeinfo
 */

// Yes, the bool here is neccessary because of how templates work
void putItem(string item, bool dec) {
	putStr(item);
}

void putItem(char item, bool dec) {
	putChr(item);
}

void putItem(bool item, bool dec) {
	if (item == true) {
		putStr("true", Color.HighLight1);
	} else {
		putStr("false", Color.HighLight1);
	}
}

void putItem(ulong item, bool dec) {
	dec ? printDecNum(item) : printHexNum(item);
}

void putItem(uint item, bool dec) {
	dec ? printDecNum(cast(ulong)(item)) : printHexNum(cast(ulong)(item));
}

void putItem(ushort item, bool dec) {
	dec ? printDecNum(cast(ulong)(item)) : printHexNum(cast(ulong)(item));
}

void putItem(ubyte item, bool dec) {
	dec ? printDecNum(cast(ulong)(item)) : printHexNum(cast(ulong)(item));
}

//////////////////////////////
//        Formatting        //
//////////////////////////////

private immutable TABLE_B16 = "0123456789ABCDEF";
private immutable TABLE_B10 = "0123456789";

// Integer to Hexadecimal conversion
private void printHexNum(ulong item) {
	char[16] buf;

	if (item == 0) {
		putStr("0x0", Color.HighLight1);
	}

	putStr("0x", Color.HighLight1);
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
private void printDecNum(ulong item) {
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