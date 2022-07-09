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
	ubyte offset;
	ushort cmd_port;
	ushort data_port;
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
	pics[0].offset    = PicOffset.One;
	pics[0].cmd_port  = 0x20;
	pics[0].data_port = 0x21;

	pics[1].offset    = PicOffset.Two;
	pics[1].cmd_port  = 0xA0;
	pics[1].data_port = 0xA1;

	// Start init
	pics[0].cmd_port.write_byte(Command.Init);
	pics[1].cmd_port.write_byte(Command.Init);

	// Offsets
	pics[0].data_port.write_byte(pics[0].offset);
	pics[1].data_port.write_byte(pics[1].offset);

	// Chaining
	pics[0].data_port.write_byte(4);
	pics[1].data_port.write_byte(2);

	// Mode
	pics[0].data_port.write_byte(LegacyMode);
	pics[1].data_port.write_byte(LegacyMode);

	// Mask all interrupts
	pics[0].data_port.write_byte(0b11111111);
	pics[1].data_port.write_byte(0b11111111);

	log(1, "PIC disabled");
}