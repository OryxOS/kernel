module lib.std.math;
// Module containing useful mathematical functions

/// Divides, rounding up if remainder is > 0
/// Params:
/// 	num = number to be divided
/// 	den = number to divide by
auto divRoundUp(T)(T num, T den) {
	return (num + (den - 1)) / den; 
}

/// Uses arch-dependant instructions to generate a random number
/// Returns:
/// 	A random size_t upon success
/// 	0 on failure 
size_t trueRandom() {
	version (X86_64) {
		// Check if `rdrand` is available
		uint result;
		asm {
			mov EAX, 1      ; 
			mov ECX, 0      ;
			cpuid           ;
			shr ECX, 30     ;
			and ECX, 1      ;
			mov result, ECX ;
		}
	}
}