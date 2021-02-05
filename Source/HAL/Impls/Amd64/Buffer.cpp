#include <Libs/Std/Types.hpp>
#include <HAL/Interface/Buffer.hpp>

using namespace Types;

void *Buffer::Copy(void *src, void *des, u64 size) {
	const char *s = static_cast<const char*>(src);
	char *d = static_cast<char*>(des);

	while (size--) *d++ = *s++;

	return des;
}

void *Buffer::Set(void *des, u64 val, u64 size) {
	const char v = static_cast<const char>(val);
	char *d = static_cast<char*>(des);

	while (size--) *d++ = v;

	return des;
}