module io.console;

import au.types;

import io.framebuffer;

static immutable pixel[4] colours = [0xFDFAEF, 0x3A4D53, 0x00866B, 0xEDEDED];

// Control Structure
private struct Console {
	bool cursor;
	ulong x; 
	ulong y;
	ulong x_limit;
	ulong y_limit;

	this(FrameBufferInfo fb) {
		this.x_limit = fb.width - fb.width % 8;
		this.y_limit = fb.height - fb.height % 16;
	}
}

private __gshared Console console;

void init_console() {
	console = Console(get_fb_info());
	clear_screen(colours[0]);
}

void moveCursor(uint x, uint y) {
	assert(x <= console.x_limit);
	assert(y <= console.y_limit);

	console.x = x;
	console.y = y;
}

void show_cursor(bool show) {
	console.cursor = show;
}

void clear_console() {
	console.x = 0;
	console.y = 0;
	clear_screen(colours[0]);
}

void put_chr(const char c, pixel col = colours[1]) {
	// End of line
	if(console.x >= console.x_limit) {
		console.y += 16;
		console.x = 0;
	}

	// Handle newlines
	switch(c) {
	case '\n':
		// Remove cursor from last line
		if (console.cursor)
			plot_rect(colours[0], console.x + 1, console.y + 1, 6, 14);

		console.y += 16;
		console.x = 0;
		break;

	case '\t':
		// Remove cursor 
		if (console.cursor)
			plot_rect(colours[0], console.x + 1, console.y + 1, 6, 14);

		if (console.x % 32 == 0) {
			console.x += 32;			
		} else {
			console.x += console.x % 32;
		}
		break;

	case '\b':
		// Remove cursor 
		if (console.cursor)
			plot_rect(colours[0], console.x + 1, console.y + 1, 6, 14);

		// Remove character
		if (console.x != 0) {
			plot_rect(colours[0], console.x - 8, console.y, 8, 16);
			console.x -= 8;
		}

		break;

	default:
		plot_chr(col, colours[0], c, console.x, console.y);
		console.x += 8;
		break;
	}

	// Scroll
	if(console.y == console.y_limit) {
		// Scroll
		scroll_screen(16, get_fb_info().height % 16);

		// Clear bottom line
		plot_rect(colours[0], 0, console.y_limit - 16, console.x_limit, 16);

		// Reset cursor
		console.y = console.y_limit - 16;
	}

	// Update cursor 
	if (console.cursor)
		plot_rect(colours[2], console.x + 1, console.y + 1, 6, 14);
}

void put_str(const string s, pixel col = colours[1]) {
	foreach (c; s) {
		put_chr(c, col);
	}
}

//////////////////////////////
//    Variadic Printing     //
//////////////////////////////

void log(T...)(uint indent, const string fmt, T args) {
	// Indentation
	foreach(_; 0..indent) {
		put_chr('\t');
	}

	put_chr('[');
	put_chr('+', colours[2]);
	put_str("] ");

	writefln(fmt, args);
}

void writefln(T...)(const string fmt, T args) {
	writef(fmt, args);
	put_chr('\n');
}

void writef(T...)(const string fmt, T args) {
	uint pos;

	foreach (arg; args) {
		// look for format specifier
		for (uint i = pos; i < fmt.length; i++) {
			if (fmt[i] == '%') {
				switch (fmt[i + 1]) {
				// String
				case 's':
					put_arg(arg, true);
					break;

				// Char
				case 'c':
					put_arg(arg, true);
					break;

				// Bool
				case 'l':
					put_arg(arg, true);			
					break;

				// Decimal number
				case 'd':
					put_arg(arg, true);
					break;

				// Integer nummber
				case 'h':
					put_arg(arg, false);
					break;

				default:
					assert(0, "Format specifier expected");
				}
				pos = i + 2; // % + Format specifier (2 chars)
				break;
			} else {
				put_chr(fmt[i]);
			}
		}
	}

	// Print remainder of string after last format specifier
	for (int i = pos; i < fmt.length; i++) {
		put_chr(fmt[i]);
	}
}

/* The following is boilerplate, but is unfortunately the 
 * best option using BetterC, which doesn't have typeinfo
 */

// Yes, the bool here is neccessary because of how templates work
void put_arg(string item, bool dec) {
	put_str(item);
}

void put_arg(char item, bool dec) {
	put_chr(item);
}

void put_arg(bool item, bool dec) {
	if (item == true) {
		put_str("true", colours[2]);
	} else {
		put_str("false", colours[2]);
	}
}

void put_arg(void* item, bool dec) {
	dec ? print_dec(cast(usize) item) : print_hex(cast(usize) item);
}

void put_arg(ulong item, bool dec) {
	dec ? print_dec(item) : print_hex(item);
}

void put_arg(uint item, bool dec) {
	dec ? print_dec(cast(ulong) item) : print_hex(cast(ulong) item);
}

void put_arg(ushort item, bool dec) {
	dec ? print_dec(cast(ulong) item) : print_hex(cast(ulong) item);
}

void put_arg(ubyte item, bool dec) {
	dec ? print_dec(cast(ulong) item) : print_hex(cast(ulong) item);
}

//////////////////////////////
//        Formatting        //
//////////////////////////////

private immutable TableB16 = "0123456789ABCDEF";
private immutable TableB10 = "0123456789";

// Integer to Hexadecimal conversion
private void print_hex(ulong item) {
	char[16] buf;

	if (item == 0) {
		put_str("0x0", colours[2]);
		return;
	}

	put_str("0x", colours[2]);
	for (int i = 15; item; i--) {
		buf[i] = TableB16[item % 16];
		item /= 16;
	}

	foreach(c; buf) {
		// Don't print unused whitespace
		if (c != char.init) {
			put_chr(c, colours[2]);
		}
	}
}
private void print_dec(ulong item) {
	char[32] buf;

	if (item == 0) {
		put_str("0", colours[2]);
		return;
	}

	for (int i = 31; item; i--) {
		buf[i] = TableB10[item % 10];
		item /= 10;
	}

	foreach(c; buf) {
		// Don't print unused whitespace
		if (c != char.init) {
			put_chr(c, colours[2]);
		}
	}
}

//////////////////////////////
//         Syscalls         //
//////////////////////////////

extern (C) void sys_put_chr(char chr, uint col) {
    put_chr(chr, col);
}

extern (C) void sys_clear_console() {
	clear_console();
}

extern (C) void sys_show_cursor(bool show) {
	show_cursor(show);
}