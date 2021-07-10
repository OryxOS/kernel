/// ACPI table parsing and analysis.
module arch.acpi;

import lib.std.stdio;


/* OryxOS ACPI initialisation
 * This module contains methods for parsing the initial ACPI tables,
 * note that this does not contain any runtime management code.
 */

private struct RsdtPointer {
    align(1):
    char[8]  signature;
    ubyte    checksum;
    char[6]  oemID;
    ubyte    revision;
    uint     rsdtAddr;
	// ACPI revision 2.0:
    uint     length;
    ulong    xsdtAddr;
    ubyte    extChecksum;
    ubyte[3] reserved;
}

private struct Rsdt {
    align(1):
    SdtHeader header;
    void*     sdtPtr;
}

struct SdtHeader {
    align(1):
    char[4] signature;
    uint    length;
    ubyte   revision;
    ubyte   checksum;
    char[6] oemID;
    char[8] oemTableID;
    uint    oemRev;
    uint    creatorID;
    uint    creatorRev; 
}

private __gshared bool  rev2;
private __gshared Rsdt* rsdt;


void initAcpi(size_t rsdpAddress) {
    const rsdp = cast(RsdtPointer*)rsdpAddress;

    if (rsdp.revision >= 2 && rsdp.xsdtAddr) {
        rev2 = true;
        rsdt = cast(Rsdt*)(cast(void*)(rsdp.xsdtAddr));
    } else {
        rev2 = false;
        rsdt = cast(Rsdt*)(cast(void*)(rsdp.rsdtAddr));
    }
}


void* getTable(char[4] signature) {
    const size_t limit = (rsdt.header.length - rsdt.header.sizeof) / (rev2 ? 8 : 4);

    SdtHeader* ptr;
    foreach (i; 0..limit) {
        if (rev2) {
            auto p = cast(ulong*)(&rsdt.sdtPtr);
            ptr = cast(SdtHeader*)p[i];
        } else {
            auto p = cast(uint*)(&rsdt.sdtPtr);
            ptr = cast(SdtHeader*)p[i];
        }

        if (ptr.signature == signature) {
            return cast(void*)ptr;
        }
    }

    return null;
}