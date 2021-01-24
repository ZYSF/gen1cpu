# Control Register/Coprocessor Interface

By default, these can only be accessed directly from system mode.

Of course, an optimised implementation could allow access to some "safe" ones directly from user mode (but otherwise this can be emulated case-by-case by trapping the instructions anyway).

## CTRL_CPUID (0)

Reading this value should give the program some idea of the available features.

The lowest byte is the maximum addressable general-purpose register (currently 15). Next byte is the architecture version (currently 1). Next byte is the maximum addressable MMU slot (currently 7).

The highest four bytes are reserved for a designer/manufacturer signature.

## CTRL_EXCN (1)

This control register will provide the last exception number.

## CTRL_FLAGS (2)

This control register will reveal information about the current CPU state, such as whether it's in system mode (which will always be true if you can read the control register!) and whether exceptions are enabled.

* Sysmode (lowest bit) determines whether the program is running in system mode (if set) or user mode (if clear)
* Excnenable (second-lowest bit) determines whether exceptions are enabled (this would generally be set except during setup or mode switching)
* Tmxenable (third-lowest bit) determines whether timer exceptions are enabled (if this is clear they will just be ignored)
* Hwxenable (fourth-lowest bit) determines whether external hardware exceptions are enabled (if this is clear they will just be ignored)
* Cpxenable (fifth-lowest bit) determines whether exceptions from other processors are enabled (this feature is only partly implemented)
* Critical (sixth-lowest bit) is meant to be set when entering a critical section (so the bus can stop other processors until a synchronised operation is complete)
* Mmuenable (seventh-lowest bit) will enable the Real-Time MMU, which is expected to have any necessary slots configured before enabling

The remainder of the lowest byte is reserved for flags, with the next byte holding the register protection setting (which defines the maximum addressable register). That is, if you set the third byte to e.g. `7`, then accessing register `8` would cause an exception rather than working correctly. However, the value of higher registers is preserved even while they are disabled. This can be set higher than the number of available registers (and defaults to `255`), in which case obviously registers are limited to those which are physically available (error handling works the same whether a register is disabled in software or doesn't exist in hardware).

The byte above the register protection byte (starting from the 16th bit) is used for extended decoding modes:

* Overlordenable (lowest bit) determines whether overlord mode is enabled (see documentation below for CTRL_OVERLORD_0 and friends)
* Instrendswap (second-lowest bit) determines whether the instruction endian is switched (this can be useful for emulating some edge cases or different instruction sets)

## CTRL_MIRRORFLAGS (3)

This is the "mirror" of the flags register, which gets swapped with the flags register during a mode switch.

In order to set specific flags, best practice is generally to apply them to the mirrorflags control register first and then perform the mode-switch to apply them (this ensures that e.g. if you're enabling the MMU then you can perform the switch startring from instructions in a physical memory location and arrive at instructions in MMU-valid memory after the switch). Note that, while switching modes and performing associated operations, it's generally necessary to disable exceptions until the new mode has been set up correctly (this may mean a couple of lower-level mode switches are required to safely perform one complete/logical "mode switch" - although in some cases it may suffice to just leave exceptions disabled until e.g. returning to user mode).

## CTRL_XADDR (4)

This is the exception address, which is jumped to when an error occurs.

## CTRL_MIRRORXADDR (5)

This is the "mirror" of the exception address.

When the exception handler is called, this will be set to the instruction at which the exception took place, and when returning from a system call this is where the program counter is taken from. This means that to skip an instruction (e.g. if it's a system call) rather than perform that operation (e.g. if it was interrupted by the timer) you will need to add 4 to this register before returning.

## CTRL_TIMER0 (6)

This is the built-in "zero" timer, which can trigger interrupts in synchronicity with the instruction clock.

NOTE: The timer interface will probably be fine-tuned a little, but having a standardised interface is important for developing portable software.

### Reading From The Timer

When reading the timer control register, the lower 8 bits are reserved for flags with the lowest being the "dingdong" flag (indicating that the alarm has gone off and you haven't reset it yet or hit sleep yet).

The rest of the bits comprise the rest of the bits of the counter (which is incremented on each instruction). The lower 8 bits are lost, however this level of accuracy shouldn't be too important (since it would take at least a few clock cycles to check the numbers anyway, it would be pretty pointless to check timing at that level).

### Setting The Timer

When writing to the timer control register, the format is different. Flags are stored in the lower bits:

* Clear (lowest bit)
* Enablealarm (second-lowest bit) will trigger the alarm (and, if enabled, a timer exception) when it hits a value (specified below)
* Enableforget (third-lowest bit) will reset the count when it hits a value (specified below)
* Sleep (fourth-lowest bit) will disable the dingdong flag.

The values for the alarm and forget thresholds are specified in 4 bits each from the 8th and 16th bits, with the resulting values being 16 left-shifted by the value of the respective bits.

Note that when handling a timer exception (i.e. if it's enabled and a dingdong occurs) the processor will automatically disable the dingdong.

## (TODO?) CTRL_TIMER1 (7)

It might be handy to have a standard timer running on a pre-determined and standardised frequency (e.g. 1MHz) in the future for the purposes of porting timing-specific software.

(This can be an issue with ARM devices even with well-specified timer peripherals, particularly to get stuff like serial working you need to know the exact configured frequency in order to work at the correct rate. For higher-level timing purposes you'd just use a battery-backed clock circuit or determine time from the network.)

## CTRL_SYSTEM0 (8) & CTRL_SYSTEM1 (9)

These are dedicated control registers for operating system usage but no not have any hardwired function other than storing some data.

Typically, these would be used when switching from user-mode to system-mode and back:

1. CTRL_SYSTEM0 might store a pointer to the current task structure
2. CTRL_SYSTEM1 might store one of the user's registers so that one register can be replaced with the task structure pointer as a base for storing the others

## CTRL_GPIOA_PINS (0xA)

This control register writes to, or reads from, the pins of the `GPIOA` I/O bus.

This just gives direct access to some pins or wires, which is particularly handy for microcontrollers (MCUs) where you might need to control some non-standard peripherals directly. Devices which don't need this can just ignore the `GPIOA` interface (i.e. not map it to any external pins) or they might disable the control register some other way.

At reset, all output pins will be set to zero. No masking or other operations happen inside the core, however this may be added as an option in the future (and there might even be multiple GPIO channels).

## CTRL_PROCESSORS (0xF)

This control register is effectively like a limited version of the GPIOA bus (it only operates/reads some external pins) but in conjunction with other features is designed for accessing a multiprocessor bus (e.g. for switching on or interrupting a secondary processor). This interface will be documented better once such configurations are tested.

## CTRL_MMU_X0 (0x10), CTRL_MMU_Y0 (0x20), CTRL_MMU_X1 (0x11), CTRL_MMU_Y1 (0x21), etc.

These are used for configuring each of the (by default 8) slots of the Real-Time MMU:

* Each `X` register determines the (1KB-aligned) virtual address of the page/segment, with size and flags in the lower bits
* Each `Y` register determines the (1KB-aligned) physical address which accesses to that page/segment get converted to (with lower bits reserved for future use)
* In normal operation, if the size/flags match, virtual addresses starting at `X` get converted to physical addresses starting at `Y`

The MMU is only active when the correpsonding `mmuenable` processor flag is set, so in other cases (assuming the MMU is present) you can use these as additional internal storage. You could even use the `Y` registers and the higher bits of `X` for custom data without enabling the registers (if they're not enabled, none of their contents will be used).

The format of the lower bits of the `X` register is as follows:

* The lowest 4 bits specifies the "size shift", where the total size is 1024 (1KB) shifted left by the contents of this value (that is you can have 1KB,2KB,4KB...32MB,64MB pages)
* The next bit is used for system mode (if it's set, this slot will cause an error if it's matched from user-mode instead)
* Next is the read flag (if this is not set and the program tries to read from an address matching this slot, it will cause an error)
* Next is the write flag (if this is not set and the program tries to write to an address matching this slot, it will cause an error)
* Next is the instr flag (if this is not set and the program tries to execute code from an address matching this slot, it will cause an error)
* Next is the io flag (if this is set then the translations will apply to I/O bus access but not to regular instructions/memory)
* Next is the enabled flag (if this isn't set, then the slot will never be matched and will not produce an error)

The lowest-matched slot is the one which is used (generally they shouldn't overlap, but behaviour should be deterministic when they do). Exceptions can be caused (if the MMU is enabled) either by an address matching a slot with invalid options (e.g. if it's only accessible for system-mode) or by an address not matching any slot.

These exceptions are currently treated the same as regular bus/fetch exceptions. Since the MMU is enabled by the flags (and these are swapped on a mode-switch including regular exceptions) you can choose to implement your kernel with MMU disabled and your user code with MMU enabled, or just keep it enabled/disabled the whole time. In either case, any necessary switching should be both seamless and immediate (e.g. even if there is a cache layer, the MMU doesn't care).

## CTRL_OVERLORD_0 (0x30), CTRL_OVERLORD_1 (0x31) .. CTRL_OVERLORD_7 (0x37)

These are used for configuring overlord mode, which allows you to overload specific instructions. If an overloaded instruction is reached it will trigger an overlord exception instead of the usual action (whether or not a corresponding instruction is implemented by the processor).

Each overlord register is (internally) 32 bits in size to ensure register-to-register compatibility between 32-bit and 64-bit implementations, making for 256 total bits. Each bit corresponds to a combination of major opcode and minor opcode (with the lower registers holding lower bits and higher registers holding higher bits).

The overloading behaviour is triggered only when overlord mode is enabled (through the flags) and only for those instructions where the corresponding overlord bit is set.

This mechanism can be useful for:

 * Fixing an instructions which might be found to be buggy in hardware
 * Adding additional security or debugging mechanisms to an instruction
 * Testing customised instructions with software before implementing them in hardware
 * Implementing any instructions which are deemed too complex to implement in hardware (i.e. to save chip space in smaller designs)
 * Emulating alternative instruction sets
