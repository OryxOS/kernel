module shell;

/* OryxOS Kernel Shell
 * This is just a simple shell in ring 0 that is nice for demoing the kernel
 */

import lib.std.stdio;
import lib.std.string;

import io.framebuffer;

import arch.amd64.drivers.legacy.keyboard; //TODO: Keyboard HAL

// Command buffer - null terminated
private __gshared char[32] cmdBuffer = '\0';
private __gshared size_t   bufferPos;

void shellMain() {
    clearConsole();

    writefln("OryxOS in-kernel shell");
    
    putStr("\n\n");
    putPromt();

    showCursor(true);

    while(1) {
        asm { hlt; }
        immutable auto event = getKeyEvent();

        if (event == '\0')
            continue;

        switch (event) {
        case '\n':
            putChr('\n');
            
            handleCommand(fromCString(&cmdBuffer[0]));

            putPromt();
            cmdBuffer[0..31] = '\0';
            bufferPos = 0;
            break;

        case '\b':
            putChr('\b');
            cmdBuffer[bufferPos--] = '\0';
            break;

        default:
            cmdBuffer[bufferPos++] = event;
            putChr(event);
            break;
        }
    }
}

private void handleCommand(string command) {
    switch (command) {
    case "say-hello":
        writefln("Hello World!");
        break;
    
    case "info":
        writefln("OryxOS version 0.0.0 (Amd64)");
        break;

    default:
        writefln("Error, command \"%s\" is not valid", command);
        return;
    }
}

private void putPromt() {
    putChr('[');
    putStr("Demo", Color.HighLight2);
    putStr("@OryxOS] > ");
}