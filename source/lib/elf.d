 module lib.elf;

/* OryxOS ELF parser
 * This module contains functions and structures that
 * are useful for parsing Elf executables
 */

private static immutable char[4] ElfIdent = [0x7F, 'E', 'L', 'F'];

// Arch specific good values
private version (X86_64) {
	enum Abi    = 0x00;
	enum Arch   = 0x3E;
	enum Endian = 0x01;
}

// Important indices into 
private enum IdentBits   = 4;
private enum IdentEndian = 5;
private enum IdentElfVer = 6;
private enum IdentOsABi  = 7;

struct Elf64Header {
	align(1):
	ubyte[16] ident; // ELF identification info
	ushort    type;  // Executable or otherwise
	ushort    arch;  // Amd64 or else
	uint      ver;   // Elf specification version

	ulong  entry;            // Executable's entry point	
	ulong  progHeaderOffset; // File offset of the program headers
	ulong  sectHeaderOffset; // File offset of the section headers
	uint   flags;
	ushort headerSize;       // Size of this header
	ushort progHeaderSize;   // Size of the program headers
	ushort progHeaderCount;  // Number of program headers
	ushort sectHeaderSize;   // Size of the section headers
	ushort sectHeaderCount;  // Number of section headers
	ushort sectHeaderSect;   // Index of the section containing the names of the section headers


}

struct ElfProgramHeader {
	uint  type;		 // Type of segment
	uint  flags;	 // Flags to load segment by
	ulong offset;    // Offset of the segment in the file
	ulong virtAddr;  // Virtual address the segment would like to be loaded at
	ulong physAddr;  // Physical address the segment would like to be loaded at (Not always needed)
	ulong fileSize;  // Size of the program on disk
	ulong memSize;   // Size of the program in memory
	ulong alignment; // Desired alignment of the segment

	enum Type {
		Null = 0x0,
		Load = 0x1,
	}
}

struct ElfSectionHeader {
	uint  nameOffset; // Offset into the .shstrtab section
	uint  type;       // Type of section
	ulong flags;      // Flags to load the section by
	ulong address;    // Desired virtual address of the section
	ulong offset;     // Offset of the section in the file
	ulong size;       // Size of the section
	uint  link;       // `type` dependant
	uint  info;       // `type` dependant
	ulong addrAlign;  // Desired alignment of the section
	ulong entrySize;  // Size of an entry into this section, if it contains entries
}