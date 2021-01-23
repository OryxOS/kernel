#include <Common/Types.hxx>
#include "Mem.hxx"

using namespace Types;

void *Mem::Copy(void *src, void *des, u64 size) {
	const char *s = static_cast<const char*>(src);
	char *d = static_cast<char*>(des);

	while (size--) *d++ = *s++;

	return des;
}

void *Mem::Set(void *des, u64 val, u64 size) {
	const char v = static_cast<const char>(val);
	char *d = static_cast<char*>(des);

	while (size--) *d++ = v;

	return des;
}