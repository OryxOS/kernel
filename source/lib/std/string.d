module lib.std.string;

private size_t stringLength(const char* str) {
	size_t len;
	for(len = 0; str[len] != '\0'; len++) {}

	return len;
}

string fromCString(const char* str) {
	return str != "\0" ? cast(string)str[0..stringLength(str)] : "";
}