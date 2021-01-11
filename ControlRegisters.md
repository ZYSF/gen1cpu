# Control Register/Coprocessor Interface

By default, these can only be accessed (directly) from system mode.

Of course, an optimised implementation could allow access to some "safe" ones directly from user mode (but otherwise this can be emulated case-by-case by trapping in system mdoe).

## CTRL_CPUID (0)

Reading this value should give the program some idea of the available features.

## CTRL_EXCN (1)

This control register will provide the last exception number.

## CTRL_FLAGS (2)

This control register will reveal information about the current CPU state, such as whether it's in system mode (which will always be true if you can read the control register!) and whether exceptions are enabled.

## CTRL_MIRRORFLAGS (3)

This is the "mirror" of the flags register, which gets swapped with the flags register during a mode switch.

## CTRL_XADDR (4)

This is the exception address, which is jumped to when an error occurs.

## CTRL_MIRRORXADDR (5)

This is the "mirror" of the exception address.

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

## (TODO?) CTRL_TIMER1 (7)

It might be handy to have a standard timer running on a pre-determined and standardised frequency (e.g. 1MHz) in the future for the purposes of porting timing-specific software.

(This can be an issue with ARM devices even with well-specified timer peripherals, particularly to get stuff like serial working you need to know the exact configured frequency in order to work at the correct rate. For higher-level timing purposes you'd just use a battery-backed clock circuit or determine time from the network.)
