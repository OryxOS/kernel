module common.scheduler;

import lib.elf;
import lib.stivale;
import lib.util.math;
import lib.util.types;
import lib.util.string;
import lib.util.console;

version (X86_64) import arch.amd64.cpu;

extern extern (C) void userMain();

void initScheduler(StivaleInfo* stivale) {
    auto moduleTag = cast(ModuleTag*) stivale.getTag(ModuleID);

    auto shellElfModule = moduleTag.getModule("application.shell");

    if (shellElfModule != null) {
        char[4]* sig = cast(char[4]*) shellElfModule.start;

        writefln("%c%c%c%c", (*sig)[0], (*sig)[1], (*sig)[2], (*sig)[3]);
    }

    //usize text = alignDown(cast(usize) &userMain, 4096);
    //Context user = Context(text, 0);
    //user.start();
}