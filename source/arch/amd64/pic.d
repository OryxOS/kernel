module arch.amd64.pic;

/* OryxOS Legacy PIC implementation
 * This is an implementation of the legacy 8259 Programmable 
 * Interrupt Controller. This code is temporary as there is no
 * situation where the PIC is the only Controller available.
 */

import arch.amd64.port;

private enum Command {
	Init = 0x11,
	EndOfInterrupt = 0x20,
}

private enum ChainMode;