module lib.std.math;
// Module containing useful mathematical functions

/// Divides, rounding up if remainder is > 0
/// Params:
/// 	num = number to be divided
/// 	den = number to divide by
auto divRoundUp(T)(T num, T den) {
	return (num + (den - 1)) / den; 
}

/// Alignes a value up to a given alignment
/// Params:
/// 	num       = number to align
/// 	alignment = value to align num to
auto alignUp(T)(T num, T alignment) {
	return divRoundUp(num, alignment) * alignment;
}

/// Alignes a value down to a given alignment
/// Params:
/// 	num       = number to align
/// 	alignment = value to align num to
auto alignDown(T)(T num, T alignment) {
	return (num / alignment) * alignment;
}
