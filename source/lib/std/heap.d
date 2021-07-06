module lib.std.heap;

/// Allocates space for an object on the heap
/// Params:
///     T = Type to allocate space for
/// Returns:
///     null = allocation failed (NEM)
///     addr = Address of the allocation
void* newObj(T)();

/// Deletes an object from the heap
bool delObj(T)(T* obj);

/// Allocates space for a contiguous array of objects on the heap
void* newArr(T)(size_t size);

/// Deletes an array of objects from the heap
bool delArr(T)(size_t size);