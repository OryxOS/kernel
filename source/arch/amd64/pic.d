module arch.amd64.pic;

/* OryxOS Legacy PIC implementation
 * This is an implementation of the legacy 8259 Programmable 
 * Interrupt Controller. This code is temporary as there is no
 * situation where the PIC is the only Controller available.
 */

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

void initPic() {
	pics[0].offset      = PicOffset.One;
	pics[0].commandPort = 0x20;
	pics[0].dataPort    = 0x21;

	pics[1].offset      = PicOffset.Two;
	pics[1].commandPort = 0xA0;
	pics[1].dataPort    = 0xA1;

	// Save masks
	auto mask1 = pics[0].dataPort.readByte();
	auto mask2 = pics[1].dataPort.readByte();

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

	// Restore masks
	pics[0].dataPort.writeByte(mask1);
	pics[1].dataPort.writeByte(mask2);
}