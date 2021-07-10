module arch.acpi;

import lib.std.stdio;

import lib.stivale;
import common.memory;

/* OryxOS ACPI initialisation
 * This module contains methods for parsing the initial ACPI tables,
 * note that this does not contain any runtime management code.
 * Only ACPI 2.0 is supported
 */

private static immutable char[8] xsdtPtrSignature = ['R', 'S', 'D', ' ', 'P', 'T', 'R', ' '];
private static immutable char[4] xsdtSignature    = ['X', 'S', 'D', 'T'];

// Extended System Descriptor Pointer 
private align (1) struct XsdtPointer {
	char[8]    signature;   // Should read "RSD PTR "
	ubyte      checksum;
	char[6]    oemIdent;
	ubyte      revision;
	uint       unused;
	uint       length;
	SdtHeader* xsdt;
	ubyte      exChecksum;
	ubyte[3]   reserved;
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

//////////////////////////////
//         Instance         //
//////////////////////////////

private __gshared SdtHeader* xsdt;

void initAcpi(StivaleInfo* stivale) {
	// Locate XSDT Pointer
	XsdtPointerTag* tag = cast(XsdtPointerTag*)(stivale.getTag(XsdtPointerID));
	XsdtPointer* ptr    = cast(XsdtPointer*)(tag.pointer);

	// Verify pointer
	if (ptr.signature != xsdtPtrSignature)
		panic("Invalid Xsdt Pointer signature");

	writefln("xsdt-addr: %h", cast(ulong)(ptr.xsdt));

	xsdt = ptr.xsdt;

	if (xsdt.signature != xsdtSignature)
		panic("Invalid Xsdt signature");

	// Print data
	log(1, "Acpi Xsdt found :: Acpi revision: %d", ptr.revision);
}

/// Attempts to locate a ACPI table
/// Params:
/// 	sig = 4 char signature of the desired table
T* getTable(T)(char[4] sig) {
	ulong* array = cast(ulong*)(xsdt + SdtHeader.sizeof);
	size_t length = (xsdt.length - SdtHeader.sizeof) / 8;

	writefln("array: %h", cast(ulong)(array));

	foreach(i; 0..length) {
		writefln("%h", cast(ulong)(array[i]));			/* ALL ARE ZERO */
	}

	// No header could be found
	return null;
}