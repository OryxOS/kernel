module arch.amd64.pic;

/* OryxOS Legacy PIC implementation
 * This is an implementation of the legacy 8259 Programmable 
 * Interrupt Controller. This code is temporary as there is no
 * situation where the PIC is the only Controller available.
 *
 * 2 Pic setup: https://os.phil-opp.com/hardware-interrupts/
 *                      ____________                          ____________
 * Real Time Clock --> |            |   Timer -------------> |            |
 * ACPI -------------> |            |   Keyboard-----------> |            |      _____
 * Available --------> | Secondary  |----------------------> | Primary    |     |     |
 * Available --------> | Interrupt  |   Serial Port 2 -----> | Interrupt  |---> | CPU |
 * Mouse ------------> | Controller |   Serial Port 1 -----> | Controller |     |_____|
 * Co-Processor -----> |            |   Parallel Port 2/3 -> |            |
 * Primary ATA ------> |            |   Floppy disk -------> |            |
 * Secondary ATA ----> |____________|   Parallel Port 1----> |____________|

 */

import lib.util.console;

import arch.amd64.cpu;

private enum Command {
	Init           = 0x11,
	EndOfInterrupt = 0x20,
}

private enum LegacyMode = 1;

private struct Pic {
	ubyte  offset;
	ushort commandPort;
	ushort dataPort;

	bool handlesInterrupt(ubyte ident) {
		return this.offset <= ident && ident < this.offset + 8; // Range of Pic
	}
}

//////////////////////////////
//         Instance         //
//////////////////////////////

// Used for setting handlers in IDT
enum PicOffset {
	One = 32,
	Two = 40,
}

private __gshared Pic[2] pics;

extern (C) void endInterrupt(ubyte ident) {
	if (pics[0].handlesInterrupt(ident)) 
		pics[0].commandPort.writeByte(Command.EndOfInterrupt);	
		
	if (pics[1].handlesInterrupt(ident)) 
		pics[1].commandPort.writeByte(Command.EndOfInterrupt);	
}

void initPic() {
	pics[0].offset      = PicOffset.One;
	pics[0].commandPort = 0x20;
	pics[0].dataPort    = 0x21;

	pics[1].offset      = PicOffset.Two;
	pics[1].commandPort = 0xA0;
	pics[1].dataPort    = 0xA1;

	// Start init
	pics[0].commandPort.writeByte(Command.Init);
	pics[1].commandPort.writeByte(Command.Init);

	// Offsets
	pics[0].dataPort.writeByte(pics[0].offset);
	pics[1].dataPort.writeByte(pics[1].offset);

	// Chaining
	pics[0].dataPort.writeByte(4);
	pics[1].dataPort.writeByte(2);

	// Mode
	pics[0].dataPort.writeByte(LegacyMode);
	pics[1].dataPort.writeByte(LegacyMode);

	// Unmask all interrupts
	pics[0].dataPort.writeByte(0b11111101);
	pics[1].dataPort.writeByte(0b11111111);

	asm { sti; }

	log(1, "Pic Initliazed in chain mode");
}