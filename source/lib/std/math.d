module lib.std.math;
// Module containing useful mathematical functions

auto divRoundUp(T)(T num, T den) {
	return (num + (den - 1)) / den; 
}