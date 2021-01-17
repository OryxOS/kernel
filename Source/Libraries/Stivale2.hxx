#include "Types.hxx"

using namespace Types;


namespace Stivale2 {   
    struct Header {
        u64 entryPoint; // Leave 0 for linker-defined entry
        u64 stackAddr;
        u64 flags;    
        u64 tags;       // Pointer to first tag or 0 if it is the least tag
    } __attribute__((__packed__));
}
