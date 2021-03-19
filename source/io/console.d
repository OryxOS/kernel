module io.console;

import specs.stivale;
import io.framebuffer;

enum Color: pixel {
	Background = 0x0D1117,
	White      = 0xC9D1D9,
}

struct Terminal {
	ushort width;
	ushort height;

	// Control variables
	private ushort xpos;
	private ushort ypos;

	this(const ref FrameBuffer fb) {
		this.width = fb.width;
		this.height = fb.height;
	}

	void putChr(const char c) {
		plotChr(Color.White, Color.Background, c, this.xpos, this.ypos);

		this.xpos += 8;

		if (this.xpos > width) {
			this.xpos = 0;
			this.ypos += 16;
		}
	}

	void putStr(string s) {
		foreach (c; s) {
			this.putChr(c);
		}
	}
	void clear() {}
}

private __gshared Terminal terminal;

void initTerminal(StivaleInfo* stivale) {
	FrameBuffer fb = initFrameBuffer(stivale);

	terminal = Terminal(fb);
}

void write(T...)(T args) {
	foreach(i; args) {
		putItem(i);
	}
}

void writeln(T...)(T args) {
	write(args, '\n');
}

// Char
private void putItem(char item) {
	terminal.putChr(item);
}

// Bool
private void putItem(bool item) {
	if (item == true) {
		terminal.putStr("True");
	} else {
		terminal.putStr("False");
	}
}

// String
private void putItem(string item) {
	terminal.putStr(item);
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
		terminal.putStr("-");
		printDecNum(-cast(size_t)(item));
	} else {
		printDecNum(item);
	}
}

// Short
void putItem(short item) {
	// Sign fix
	if(item < 0) {
		terminal.putStr("-");
		printDecNum(-cast(size_t)(item));
	} else {
		printDecNum(item);
	}
}

// Int
void putItem(int item) {
	// Sign fix
	if(item < 0) {
		terminal.putStr("-");
		printDecNum(-cast(size_t)(item));
	} else {
		printDecNum(item);
	}
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
		terminal.putStr("0x0");
	}

	terminal.putStr("0x");
	for (int i = 15; item; i--) {
		buf[i] = TABLE_B16[item % 16];
		item /= 16;
	}

	foreach(c; buf) {
		// Don't print unused whitespace
		if (c != char.init) {
			terminal.putChr(c);
		}
	}
}

private void printDecNum(size_t item) {
	char[16] buf;

	if (item == 0) {
		terminal.putStr("0");
	}

	for (int i = 15; item; i--) {
		buf[i] = TABLE_B10[item % 10];
		item /= 10;
	}

	foreach(c; buf) {
		// Don't print unused whitespace
		if (c != char.init) {
			terminal.putChr(c);
		}
	}
}