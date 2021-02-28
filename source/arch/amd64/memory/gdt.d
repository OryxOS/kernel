module arch.amd64.memory.gdt;

// GDT pointer loaded with lgdt
private align(1) struct GdtPointer {
	ushort limit;   // last gdt entry (size - 1)
	void*  base;    // Virtual address of the GDT

	this(GdtDescriptor* entries) {
		this.base = cast(void*)(entries);
		this.limit = entries.sizeof - 1;
	}
}

private align(1) struct GdtDescriptor {
	ushort limit;
	ushort lowBase;
	ubyte  midBase;
	ushort flags;
	ubyte  highBase;

	this(ushort flags) {
		this.limit    = 0;
		this.lowBase  = 0;
		this.midBase  = 0;
		this.highBase = 0;

		this.flags = flags;
	}
}

private enum Flags: ushort {
	// Flag:                  Segments:         Description:
	Accessed       = 1 << 0,  // Code | Data    Set by cpu
	Conforming     = 1 << 2,  // Code |         Influences privilege checks
	Executable     = 1 << 3,  // Code |         Required for Code segments
	Code           = 1 << 4,  // Code |         Makes the segment a code segment
	Data           = 0 << 4,  //      | Data    Makes the segment a data segment
	User           = 3 << 5,  // Code | Data    Makes the segment user-accessible
	Present        = 1 << 7,  // Code | Data    Present in memory
	Available      = 1 << 12, // Code | Data    Available for use
	LongMode       = 1 << 13, // Code |         Required for long mode code segs
}

//////////////////////////////
//         Instance         //
//////////////////////////////

private __gshared GdtDescriptor[3] gdtEntries;
private __gshared GdtPointer gdtPointer = GdtPointer(gdtEntries.ptr);

// Selectors
immutable CODE_SEGMENT = 0x08;       
immutable DATA_SEGMENT = 0x10;


// Function to be called by main
void initGdt() {
	// Null Descriptor
	gdtEntries[0] = GdtDescriptor(0);
	// Kernel Code Segment Descriptor                               
	gdtEntries[1] = GdtDescriptor(Flags.Executable | Flags.Code 
									| Flags.Present | Flags.Available 
									| Flags.LongMode);
	// Kernel Data Segment Descriptor
	gdtEntries[2] = GdtDescriptor(Flags.Data | Flags.Present | Flags.Available);

	// Load the new GDT
	asm {
        lgdt [gdtPointer];

        // Long jump to set cs and ss.
        mov RBX, RSP;
        push DATA_SEGMENT;
        push RBX;
        pushfq;
        push CODE_SEGMENT;
        lea RAX, L1; // Putting L1 directly dereferences L1 cause D dum dum.
        push RAX;
        iretq;

    L1:;
        mov AX, DATA_SEGMENT;
        mov DS, AX;
        mov ES, AX;
        mov FS, AX;
        mov GS, AX;
    }
}