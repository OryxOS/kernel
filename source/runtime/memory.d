deprecated("Compiler intrinsics. Do not invoke") module runtime.memory;

import au.types;

version (X86_64) {
	// `rep movsb` memcpy implementation
	extern (C) void* memcpy(void* dest, const void* src, usize n) {
		asm {
			mov RCX, n      ; // Count
			mov RSI, src    ; // Source
			mov RDI, dest   ; // Destination
			rep             ;
			movsb           ;
		}

		return dest;
	}

	// `rep stosb` memset implementation
	extern (C) void* memset(void* s, int c, ulong n) {
		asm {
			mov RCX, n      ; // Count
			mov RAX, c      ; // Value
			mov RDI, s      ; // Destination
			rep             ;
			stosb           ;
		}

		return s;
	}
}

// `_d_array_slice_copy` llvm intrinsic.
extern (C) void _d_array_slice_copy(void* dst, usize dstlen, void* src, usize srclen, usize elemsz) {
        import ldc.intrinsics : llvm_memcpy;
        llvm_memcpy!usize(dst, src, dstlen * elemsz, 0);
}

// memcmp implementation, should be arch-indpendent
extern (C) int memcmp(const void *s1, const void *s2, usize n) {
    auto p1 = cast(ubyte*) s1;
    auto p2 = cast(ubyte*) s2;
 
    for (usize i = 0; i < n; i++) {
        if (p1[i] != p2[i])
            return p1[i] < p2[i] ? -1 : 1;
    }
 
    return 0;
}