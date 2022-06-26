module io.console;

import au.types;

import io.framebuffer;
import io.framebuffer.fancy;

static immutable pixel[4] darkTheme  = [0x161414, 0xD7D5D5, 0x00866B, 0x393939];
static immutable pixel[4] lightTheme = [0xFDFAEF, 0x3A4D53, 0x00866B, 0xEDEDED];

// Control Structure
private struct Console {
	bool showCursor;
	ulong posX; 
	ulong posY;
	ulong maxX;
	ulong maxY;

	this(FrameBufferInfo fb) {
		this.maxX = fb.width - fb.width % 8;
		this.maxY = fb.height - fb.height % 16;
	}
}

private __gshared Console console;

__gshared pixel[4] theme;

void initConsole() {
	console = Console(getFrameBufferInfo());
	theme   = lightTheme;

	plotScreen(theme[0]);
}

void setTheme(bool dark) {
	if (dark)
		theme = darkTheme;
	else
		theme = lightTheme;
}

void moveCursor(uint x, uint y) {
	assert(x <= console.maxX);
	assert(y <= console.maxY);

	console.posX = x;
	console.posY = y;
}

void showCursor(bool show) {
	console.showCursor = show;
}

void clearConsole() {
	console.posX = 0;
	console.posY = 0;
	plotScreen(theme[0]);
}

void putChr(const char c, pixel col = theme[1]) {
	// End of line
	if(console.posX >= console.maxX) {
		console.posY += 16;
		console.posX = 0;
	}

	// Handle newlines
	switch(c) {
	case '\n':
		// Remove cursor from last line
		if (console.showCursor)
			plotRect(theme[0], console.posX + 1, console.posY + 1, 6, 14);

		console.posY += 16;
		console.posX = 0;
		break;

	case '\t':
		// Remove cursor 
		if (console.showCursor)
			plotRect(theme[0], console.posX + 1, console.posY + 1, 6, 14);

		if (console.posX % 32 == 0) {
			console.posX += 32;			
		} else {
			console.posX += console.posX % 32;
		}
		break;

	case '\b':
		// Remove cursor 
		if (console.showCursor)
			plotRect(theme[0], console.posX + 1, console.posY + 1, 6, 14);

		// Remove character
		if (console.posX != 0) {
			plotRect(theme[0], console.posX - 8, console.posY, 8, 16);
			console.posX -= 8;
		}

		break;

	default:
		plotChr(col, theme[0], c, console.posX, console.posY);
		console.posX += 8;
		break;
	}

	// Scroll
	if(console.posY == console.maxY) {
		scrollScreen(16, getFrameBufferInfo().height % 16);          // Move new data up
		plotRect(theme[0], 0, console.maxY - 16, console.maxX, 16);  // Clear line
		console.posY = console.maxY - 16;                            // Reset cursor
	}

	// Update cursor 
	if (console.showCursor)
		plotRect(theme[2], console.posX + 1, console.posY + 1, 6, 14);
}

void putStr(const string s, pixel col = theme[1]) {
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
	putChr('+', theme[2]);
	putStr("] ");

	writefln(fmt, args);
}

void panic(string file = __FILE__, usize line = __LINE__, T...)(const string fmt, T args) {
	showCursor(false);
	plotScreen(theme[0]);

	// !!!
	auto start = getFrameBufferInfo().width / 2 - 72;
	plotExclamation(theme[2], start, 8);
	plotExclamation(theme[2], start + 56, 8);
	plotExclamation(theme[2], start + 112, 8);

	// "A fatal error has occured"
	console.posX = console.maxX / 2 - (cast(uint)("A fatal error has occured".length / 2) * 8);
	console.posY = 112;
	putStr("A fatal error has occured", theme[2]);

	// (Line)
	console.posX = 0;
	console.posY = 128;
	foreach(_; 0..console.maxX / 8) {
		putChr('-', theme[2]);
	}

	// Reset for printing
	console.posX = 0;
	console.posY = 176;

	// Info message
	writefln("\t\tA fatal error has occured and the system must be restarted
		This error hass likely occured due to poor hardware support.
		If you are using a nightly image of OryxOS, please report
		this crash and try a stable image");

	// Context
	putStr("\n\n\n\t\t// For developers\n", theme[3]);
	writefln("\t\tContext:
		File: %s
		Line: %d", file, line);
	putStr("\n\t\t");
	writefln(fmt, args);

	// Hang the kernel
	version(X86_64) {
		asm {
			cli;
			hlt;
		}
	} else {
		while(1) {}
	}
}

void writefln(T...)(const string fmt, T args) {
	writef(fmt, args);
	putChr('\n');
}

void writef(T...)(const string fmt, T args) {
	uint strPos;

	foreach (arg; args) {
		// look for format specifier
		for (uint i = strPos; i < fmt.length; i++) {
			if (fmt[i] == '%') {
				switch (fmt[i + 1]) {
				case 's':              // String
					putItem(arg, true);
					break;

				case 'c':
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
		putStr("true", theme[2]);
	} else {
		putStr("false", theme[2]);
	}
}

void putItem(void* item, bool dec) {
	dec ? printDecNum(cast(usize) item) : printHexNum(cast(usize) item);
}

void putItem(ulong item, bool dec) {
	dec ? printDecNum(item) : printHexNum(item);
}

void putItem(uint item, bool dec) {
	dec ? printDecNum(cast(ulong) item) : printHexNum(cast(ulong) item);
}

void putItem(ushort item, bool dec) {
	dec ? printDecNum(cast(ulong) item) : printHexNum(cast(ulong) item);
}

void putItem(ubyte item, bool dec) {
	dec ? printDecNum(cast(ulong) item) : printHexNum(cast(ulong) item);
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
		putStr("0x0", theme[2]);
		return;
	}

	putStr("0x", theme[2]);
	for (int i = 15; item; i--) {
		buf[i] = TABLE_B16[item % 16];
		item /= 16;
	}

	foreach(c; buf) {
		// Don't print unused whitespace
		if (c != char.init) {
			putChr(c, theme[2]);
		}
	}
}
private void printDecNum(ulong item) {
	char[32] buf;

	if (item == 0) {
		putStr("0", theme[2]);
		return;
	}

	for (int i = 31; item; i--) {
		buf[i] = TABLE_B10[item % 10];
		item /= 10;
	}

	foreach(c; buf) {
		// Don't print unused whitespace
		if (c != char.init) {
			putChr(c, theme[2]);
		}
	}
} 