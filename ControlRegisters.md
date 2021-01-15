# Control Register/Coprocessor Interface

By default, these can only be accessed directly from system mode.

Of course, an optimised implementation could allow access to some "safe" ones directly from user mode (but otherwise this can be emulated case-by-case by trapping the instructions anyway).

## CTRL_CPUID (0)

Reading this value should give the program some idea of the available features.

## CTRL_EXCN (1)

This control register will provide the last exception number.

## CTRL_FLAGS (2)

This control register will reveal information about the current CPU state, such as whether it's in system mode (which will always be true if you can read the control register!) and whether exceptions are enabled.

* Sysmode (lowest bit) determines whether the program is running in system mode (if set) or user mode (if clear)
* Excnenable (second-lowest bit) determines whether exceptions are enabled (this would generally be set except during setup or mode switching)
* Tmxenable (third-lowest bit) determines whether timer exceptions are enabled (if this is clear they will just be ignored)
* Hwxenable (fourth-lowest bit) determines whether external hardware exceptions are enabled (if this is clear they will just be ignored)

## CTRL_MIRRORFLAGS (3)

This is the "mirror" of the flags register, which gets swapped with the flags register during a mode switch.

In order to set specific flags, you have to apply them to the mirrorflags control register first and then perform the mode-switch to apply them.

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

## CTRL_GPIOA_PINS (0xA)

This control register writes to, or reads from, the pins of the `GPIOA` I/O bus.

This just gives direct access to some pins or wires, which is particularly handy for microcontrollers (MCUs) where you might need to control some non-standard peripherals directly. Devices which don't need this can just ignore the `GPIOA` interface (i.e. not map it to any external pins) or they might disable the control register some other way.

At reset, all output pins will be set to zero. No masking or other operations happen inside the core, however this may be added as an option in the future (and there might even be multiple GPIO channels)
