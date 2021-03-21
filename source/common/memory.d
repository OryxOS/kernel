module common.memory;

import specs.stivale;

// Non arch-specific memory related stuff

/* We create our own Memory map stuff for
 * 2 reasons, Firstly, independance and secondly
 * this allows us to design the allocator more to
 * our liking
 */

// Do not modify, this matches the stivale spec
enum RegionType: uint {
	Usable                = 1,
	Reserved              = 2,
	AcpiReclaimable       = 3,
	AcpiNvs               = 4,
	Bad                   = 5,
	BootloaderReclaimable = 0x1000,
	KernelOrModule        = 0x1001
 }

// Do not modify, this matches the stivale spec
align(1) struct Region {
	ulong      base;
	ulong      length;
	RegionType type;
	uint       unused;
}

// Region info struct
struct RegionInfo {
	ulong    count;
	Region*  regions;

	this(MemMapTag* tag) {
		this.count = tag.entryCount;
		this.regions = &tag.entries;
	}
}