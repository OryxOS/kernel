module arch.amd64.pic;

/* OryxOS Legacy PIC management
 * This code has only 1 job, and that is to correctly disable the PIC
 */

import io.console;

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

enum PicOffset {
	One = 32,
	Two = 40,
}

private __gshared Pic[2] pics;

void disablePic() {
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

	// Mask all interrupts
	pics[0].dataPort.writeByte(0b11111111);
	pics[1].dataPort.writeByte(0b11111111);

	log(1, "PIC disabled");
}