module common.memory.map;

import lib.limine;

// Module for managing memory maps

// Do not modify, this matches the limine spec
enum RegionType: ulong {
	Usable                = 0,
	Reserved              = 1,
	AcpiReclaimable       = 2,
	AcpiNvs               = 3,
	Bad                   = 4,
	BootloaderReclaimable = 5,
	KernelOrModule        = 6,
	FrameBuffer           = 7
 }

// Do not modify, this matches the limine spec
struct Region {
	align (1):
	ulong      base;
	ulong      length;
	RegionType type;
}

// Region info struct
struct RegionInfo {
	ulong    count;
	Region**  regions;

	this(MemoryMapResponse* response) {
		this.count = response.entryCount;
		this.regions = response.entries;
	}
}