# gen1cpu

Finally, a CPU that isn't mind-numbingly complex. Batteries sold separately.

Implemented in Verilog and featuring a custom-designed instruction set (completely copyright-free!).

Designed to be deployed in microcontrollers (MCUs) for security-sensitive devices (particularly robotics and communications devices), but not yet adequately-tested or extended for real world use. May be more applicable to general-purpose computing in the future, but security concerns are prioritised over efficiency concerns.

## Features

* Basic integer maths (other operations can be added easily for larger designs)
* Basic control flow (decision-making, looping and function calls)
* Basic system-mode/user-mode functionality, complete with mode switching, invalid-instruction handling and interrupt handling
* Built-in timer peripheral (so multitasking can be implemented without any additional peripherals, TODO: test that)
* Reasonably lightweight (may not fit on all embedded FPGAs but should on recent/mid-range ones, very small codebase)
* Custom [instruction set](InstructionSet.md) with no proprietary tricks (as far as I know I haven't used anything which aligns to any particular proprietary ISA, and the code is PUBLIC DOMAIN)
* Supports up to 256 general-purpose registers, with up to 16 being accessible in instructions with limited space
* Two options for I/O: A direct 64-bit core-to-pin interface ("GPIOA"), or a classic I/O bus with similar semantics to the memory bus
* Basic feature detection (at least can check major version number and number of registers)

## Code Overview

* The CPU itself is defined entirely in `SimpleCore.v`
* The `SimpleMCU.v` module is a simple top-level implementation for an FPGA with a few LED outputs and one clock input, this will just run some simple instructions and blink the LEDs

## Documentation

* [Instruction Set](InstructionSet.md) documents the semantics and encoding of each of the standard instructions.
* [Control Registers](ControlRegisters.md) documents the meanings, encodings and indices of the control registers.
* [Modes & Exceptions](ModesAndExceptions.md) documents the user-mode/system-mode switching and the meanings of the exception codes.
* [Design & Planning](DesignAndPlanning.md) should answer questions like "why not just use RISC-V?" and "why does it support 256 registers?"

## Tools

* [ZAsm](https://github.com/ZYSF/ZAsm/) a simple but flexible assembler which supports the new instruction set.
* [ZLink](https://github.com/ZYSF/ZLink/) a linker which can produce flat binaries from the assembled code.
* A C compiler is also in development.
