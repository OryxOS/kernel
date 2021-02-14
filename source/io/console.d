module io.console;

version(X86_64) import arch.amd64.text; 

private immutable CONVERSION_TABLE = "0123456789abcdef";

void clear() {
	// Has to be done to avoid recursion
	version(X86_64) arch.amd64.text.clear(); 
}

void log(T...)(T fmt) {
	format(fmt);
}

void logln(T...)(T fmt) {
	format(fmt, '\n');
}

private {
	void format(T...)(T items) {
		foreach(i; items) {
			putItem(i);
		}
	}

	// Char
	void putItem(char item) {
		putChr(item);
	}

	// String
	void putItem(string item) {
		putStr(item);
	}

	// Integers. Cast all to size_t and work from there
	void putItem(ubyte item) {
		putItem(cast(size_t)(item));
	}

	void putItem(ushort item) {
		putItem(cast(size_t)(item));
	}

	void putItem(uint item) {
		putItem(cast(size_t)(item));
	}

	// size_t
	void putItem(size_t item) {
		char[16] buf;

		if (item == 0) {
			putStr("0x0");
		}

		// Backwards order
		putStr("0x");
		for (int i = 16; item; i--) {
			buf[i] = CONVERSION_TABLE[item % 16];
			item /= 16;
		}

		foreach(c; buf) {
			// Don't print unused whitespace
			if (c != char.init) {
				putChr(c);
			}
		}
	}
}