#pragma once

#include <Common/Types.hxx>

using namespace Types;

namespace Mem {
	void *Copy(void *src, void *des, u64 size);	// Copies a specified amoun of data from one buffer to another
	void *Set(void *des, u64 val, u64 size);	// Sets an enire buffer to a value
}