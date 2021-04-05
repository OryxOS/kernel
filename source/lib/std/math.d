module lib.std.math;
// Module containing useful mathematical functions

/// Divides, rounding up if remainder is > 0
/// Params:
/// 	num = number to be divided
/// 	den = number to divide by
auto divRoundUp(T)(T num, T den) {
	return (num + (den - 1)) / den; 
}