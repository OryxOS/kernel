module arch.amd64.memory.virtual;

import arch.amd64.memory;
import arch.amd64.memory.physical;

/* OryxOS Amd64 Virtual Memory Manager
 *
 * Terms:
 *      Root    : Top-level paging table (Loaded into Cr3) (512 pointers to L1Tables)
 *      L1Table : Level down                               (512 pointers to L2Tables)
 *      L2Table : Level down                               (512 pointers to Pages)
 *      Page    : 4 kilobytes of space
 *
 * All tables must be 4kb aligned. The best way to do this is to allocate a block of
 * physical memory for each Table
 */

private alias Table = ulong[512];

private struct AddressSpace {
    Table* root;

    shared this(shared void* rootBlock) {
        // Ensure space given is 4kb aligned
        assert (cast(ulong)(rootBlock) % PageSize == 0);

        this.root = cast(shared Table*)(rootBlock);
    }
}

private shared AddressSpace kernelSpace;

void initVmm() {
    // Alloc enough space for root table
    PmmResult rootBlock = newBlock(1);

    if (rootBlock.isOkay) {
       // kernelSpace = AddressSpace(cast(shared void*)(rootBlock.unwrapResult));
    } else {
        
    }
}