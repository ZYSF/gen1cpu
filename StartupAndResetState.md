# Startup & Reset State

## Startup & Reset

These are basically the same thing, so you can expect the processor core to be in the same internal state immediately after either a successful startup or a successful hot restart.

## Initial Register States

* All general-purpose registers are cleared to zero
* Any timer counters are cleared to zero
* The `CTRL_SYSTEM0` control register is cleared to zero
* The flags and mirrorflags are set to constant values (currently, both the value 1 `or`-ed with the mask enabling each register, which means system mode and the registers are the only flags specifically enabled, while MMU and exceptions are disabled)
* `CTRL_TIMER`, `CTRL_GPIOA`, `CTRL_XADDR` and other control registers should be cleared to default or zero
* The program counter is _by default_ initialised to zero, which means the core starts running code from instructions at address zero (although this might be made easier-to-change in the future)

## Startup & Reset At The Hardware Level

Internally, the core expects it's `reset` input to go high when resetting. Or in other words, you just make the `reset` pin equal `true` (1).

On an external bus this might be inverted (so reset happens _until_ the pin is set, which makes more sense when you're turning a machine on, but less sense as a logical input). In some designs reset might be operated via some other mechanism (which might also reset other internal modules in synchronicity).

As long as the reset is happening, most internal registers and outputs of the core will be pulled to zero (otherwise to some other initial state) and the usual progression through instructions will be disabled.

Memory and I/O outputs from the core should all read zero during reset, and it shouldn't process any inputs (whether those are zero or not).

The clock is expected to run _at least a little bit_ during a reset (or, at least, the clock input should warm up before the reset ends to ensure that at least one complete cycle of active resetting has happened). In other words, ending the reset phase must be delayed slightly when powering on a device, until after the clock source is known to have produced some cycles.

The `SimpleMCU.v` file simply drives the core's reset input by counting clock cycles from FPGA startup (which would probably use it's own reset pin or similar interface on the dev board).

So it's usually pretty easy to create a startup method for a particular device configuration, it might just require some simple logic.
