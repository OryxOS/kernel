module arch.amd64.text;

enum Color: ubyte {
		Black,
		Blue,
		Green,
		Cyan,
		Red,
		Purple,
		Brown,
		Gray,
		DarkGray,
		LightBlue,
		LightGreen,
		LightCyan,
		LightRed,
		LightPurple,
		Yellow,
		White,
}

private {
	__gshared ulong posX = 0;
	__gshared ulong posY = 0;

	__gshared Color fg = Color.Black;
	__gshared Color bg = Color.White;

	__gshared ushort* buffer = cast(ushort*)(0xb8000);
}

void putChr(const char c) @trusted {
	// End of line
	if(posX > 80) {
		posY++;
		posX = 0;
	}

	// Scroll needed
    if (posY >= 25) {
		posY = 24;
		posX = 0;

		buffer[0..1920] = buffer[80..2000];
		buffer[1920..2000] = cast(ushort)(' ' | ((fg | bg << 4) << 8));
	}

	// Handle newlines
	switch(c) {
		case '\n':
			posY++;
			posX = 0;
			break;

	default:
			buffer[posX + 80 * posY] = cast(ushort)(c | ((fg | bg << 4) << 8));
			posX++;
			break;
	}
}

void putStr(string s) {
	foreach (c; s) {
		putChr(c);
	}
}

void clear() {
	buffer[0..2000] = cast(ushort)(' ' | ((fg | bg << 4) << 8));
}