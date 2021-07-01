module arch.acpi;

import lib.std.stdio;

import lib.stivale;
import common.memory;

/* OryxOS ACPI initialisation
 * This module contains methods for parsing the initial ACPI tables,
 * note that this does not contain any runtime management code.
 * Only ACPI 2.0 is supported
 */

private static immutable XsdtPtrSignature = ['R', 'S', 'D', ' ', 'P', 'T', 'R', ' '];
private static immutable XsdtSignature    = ['X', 'S', 'D', 'T'];

// Extended System Descriptor Pointer 
private align (1) struct XsdtPointer {
	char[8]  signature;   // Should read "RSD PTR "
	ubyte    checksum;
	char[6]  oemIdent;
	ubyte    revision;
	uint     unused;
	uint     length;
	Xsdt*    xsdt;
	ubyte    exChecksum;
	ubyte[3] reserved;
}

// System Descriptor Table Header
align (1) struct SdtHeader {
	char[4] signature;
	uint    length;
	ubyte   revision;
	ubyte   checksum;
	char[6] oemIdent;
	char[8] oemTableIdent;
	uint    oemRevision;
	uint    creatorIdent;
	uint    creatorRevision;
}

// Extended System Descriptor Table
private align (1) struct Xsdt {
	SdtHeader  header;
	void*      tables; // Array of all the other ACPI tables
}

//////////////////////////////
//         Instance         //
//////////////////////////////

private __gshared Xsdt* xsdt;

void initAcpi(StivaleInfo* stivale) {
	// Locate XSDT Pointer
	XsdtPointerTag* tag = cast(XsdtPointerTag*)(stivale.getTag(XsdtPointerID));
	XsdtPointer* ptr    = cast(XsdtPointer*)(tag.pointer);

	// Verify pointer
	if (ptr.signature != XsdtPtrSignature)
		panic("Invalid Xsdt Pointer signature");

	xsdt = ptr.xsdt;

	if (xsdt.header.signature != XsdtSignature)
		panic("Invalid Xsdt signature");

	// Print data
	log(1, "Acpi Xsdt found :: Acpi revision: %d", ptr.revision);
}

/// Attempts to locate a ACPI table
/// Params:
/// 	sig = 4 char signature of the desired table
void* getTable(char[4] sig) {
	immutable auto entryCount = (xsdt.header.length - xsdt.header.sizeof) / 8;

	for (size_t i = 0; i < entryCount; i++) {
		SdtHeader* hdr = cast(SdtHeader*)(&xsdt.tables + 1 * 8);

		if (hdr.signature == sig)
			return cast(void*)(hdr);
	}

	// No header could be found
	return null;
}