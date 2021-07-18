module lib.util.string;

import lib.util.types;

private usize stringLength(const char* str) {
	usize len;
	for(len = 0; str[len] != '\0'; len++) {}

	return len;
}

/// Converts a C style string to a D style string
string fromCString(const char* str) {
	return str != "\0" ? cast(string) str[0..stringLength(str)] : "";
}