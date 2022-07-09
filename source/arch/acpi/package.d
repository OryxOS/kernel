module arch.acpi;

import lib.limine;
import au.types;
import io.console;

import memory;

/* OryxOS ACPI initialisation
 * This module contains methods for parsing the initial ACPI tables,
 * note that this does not contain any runtime management code.
 */

private struct RsdtPointer {
    align(1):
    char[8] signature;
    ubyte checksum;
    char[6] oem_id;
    ubyte revision;
    uint rsdt_addr;

	// ACPI revision 2.0:
    uint length;
    ulong xsdt_addr;
    ubyte checksum_ext;
    ubyte[3] reserved;
}

private struct Rsdt {
    align(1):
    SdtHeader header;
    void* sdt_ptr;
}

struct SdtHeader {
    align(1):
    char[4] signature;
    uint length;
    ubyte revision;
    ubyte checksum;
    char[6] oem_id;
    char[8] oem_tbl_id;
    uint oemRev;
    uint creator_id;
    uint creator_rev; 
}

private __gshared bool  rev2;
private __gshared Rsdt* rsdt;

//////////////////////////////
//         Instance         //
//////////////////////////////

void init_acpi(XsdtPointerResponse* xsdt_ptr) {
    auto rsdp = cast(RsdtPointer*) xsdt_ptr.address;

    // Check if we are working with ACPI revision 1 or 2
    rev2 = rsdp.revision >= 2 && rsdp.xsdt_addr;

    rsdt = rev2 ? cast(Rsdt*) (cast(void*) rsdp.xsdt_addr + PhysOffset)
                : cast(Rsdt*) (cast(void*) rsdp.rsdt_addr);

    log(1, "ACPI root table found. ACPI Revision: %d", rsdp.revision);
}

/// Attempts to locate a ACPI table
/// Params:
/// 	sig = 4 char signature of the desired table
/// Returns:
///     null = table does not exist
void* get_table(char[4] signature) {
    const usize limit = (rsdt.header.length - rsdt.header.sizeof) / (rev2 ? 8 : 4);

    // Loop through and find the table
    SdtHeader* ptr;
    foreach (i; 0..limit) {
        // Revision 2 pointers are 64 bit
        ptr = rev2 ? cast(SdtHeader*) ((cast(ulong*) &rsdt.sdt_ptr)[i] + PhysOffset)
                   : cast(SdtHeader*) ((cast(uint*) &rsdt.sdt_ptr)[i] + PhysOffset);
        
        // Table found
        if (ptr.signature == signature)
            return cast(void*) ptr;
    }

    // Table not found
    return null;
}