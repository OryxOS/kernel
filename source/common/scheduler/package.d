module common.scheduler;

import lib.util.math;
import lib.util.types;
import lib.util.console;

version (X86_64) import arch.amd64.cpu;

extern extern (C) void userMain();

void initScheduler() {
    usize text = alignDown(cast(usize) &userMain, 4096);

    Context user = Context(text, 0);

    user.start();
}