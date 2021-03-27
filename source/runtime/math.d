module runtime.math;

auto divRoundUp(T)(T num, T den) {
    return (num + (den - 1)) / den; 
}