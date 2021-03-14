module io.console;

import io.framebuffer;

void clear() {
	// Has to be done to avoid recursion
	io.framebuffer.clear(); 
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
	putChr(item);
}

// Bool
private void putItem(bool item) {
	if (item == true) {
		putStr("True");
	} else {
		putStr("False");
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
		putStr("-");
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
//        Formatting        //
//////////////////////////////

enum FormatFlags: uint {
	Hex    = 1 << 0,
}

private immutable TABLE_B16 = "0123456789abcdef";
private immutable TABLE_B10 = "0123456789";

// Integer to Hexadecimal conversion
private void printHexNum(size_t item) {
	char[16] buf;

	if (item == 0) {
		putStr("0x0");
	}

	putStr("0x");
	for (int i = 15; item; i--) {
		buf[i] = TABLE_B16[item % 16];
		item /= 16;
	}

	foreach(c; buf) {
		// Don't print unused whitespace
		if (c != char.init) {
			putChr(c);
		}
	}
}

private void printDecNum(size_t item) {
	char[16] buf;

	if (item == 0) {
		putStr("0");
	}

	for (int i = 15; item; i--) {
		buf[i] = TABLE_B10[item % 10];
		item /= 10;
	}

	foreach(c; buf) {
		// Don't print unused whitespace
		if (c != char.init) {
			putChr(c);
		}
	}
}