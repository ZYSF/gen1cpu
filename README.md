# gen1cpu

Finally, a CPU that isn't mind-numbingly complex. Batteries sold separately.

Implemented in Verilog and featuring a custom-designed instruction set (completely copyright-free!).

Designed to be deployed in microcontrollers (MCUs) for security-sensitive devices (particularly robotics and communications devices), but not yet adequately-tested or extended for real world use. May be more applicable to general-purpose computing in the future, but security concerns are prioritised over efficiency concerns.

## Current Status

As of early 2021, I'm still actively adding features and tools. The main feature which is lacking at the moment is a proper test suite (and any resulting bugfixes!), but additional optimisations and other features would also be desirable.

A "proper test suite" would probably have to begin with simulated builds for practical reasons. Some (limited) informal testing has already been done both on Cyclone 10 FPGA and by simulating in Icarus Verilog.

## Features

* Custom [instruction set](InstructionSet.md) (no copying of proprietary encodings)
* Reasonably lightweight 64-bit implementation (very small codebase and suitable for convenient FPGA boards and 32-bit memory interfaces)
* Basic integer maths ("standard operations" include addition, subtraction, shifting, and/or/xor)
* Basic control flow (comparisons, looping and function calls)
* Exception handling (so you can recover from invalid/disabled/overloaded instructions, bus errors, hardware interrupts and the like)
* System-mode/user-mode switching and ability to accurately save/restore program state
* Real-Time Memory Management Unit with support for 8 or more flexible pages/segments mapped simultaneously
* Register protection, so you can even restrict access to internal (as well as external) memory
* Double-fault detection (if exception handling is misconfigured the core goes into a special mode until reset)
* Built-in timer peripheral (so multitasking can be implemented without any additional peripherals)
* Supports up to 256 general-purpose registers for basic operations (restricted to 16 "standard registers" for instructions with limited space)
* Extensible encoding for ALU operations (larger implementations can define up to 65536 different math operations using the `xlu` encoding)
* Able to load constant values up to 24 bits in a single instruction (with a special instruction for appending additional bits for larger constants)
* Two options for I/O: A direct 64-bit core-to-pin interface ("GPIOA"), or a classic I/O bus with similar semantics to the memory bus
* Basic feature detection (at least can check major version number and number of registers)

## Code Overview

* The CPU itself is defined entirely in `SimpleCore.v`
* The `SimpleMCU.v` module is a simple top-level implementation for an FPGA with a few LED outputs and one clock input, this will just run some simple instructions and blink the LEDs
* `SimpleTests.v` and `SimpleCore-tests.sh` are a simple top-level and test script for use with Icarus Verilog and Bash (NOTE: The testing isn't very formal yet but this should be enough to get started stepping through instructions and seeing if they work)

## Documentation

### Technical Specifications

* [Instruction Set](InstructionSet.md) documents the semantics and encoding of each of the standard instructions.
* [Control Registers](ControlRegisters.md) documents the meanings, encodings and indices of the control registers.
* [Modes & Exceptions](ModesAndExceptions.md) documents the user-mode/system-mode switching and the meanings of the exception codes.
* [Startup & Reset State](StartupAndResetState.md) documents the startup/reset sequence and what state to expect the core to be in at initialisation.
* [Addressing Modes](AddressingModes.md) should help to clarify the role of the MMU and the ways in which instructions, memory locations, I/O and control registers are addressed

### Design & Business Documents

* [Design & Planning](DesignAndPlanning.md) should answer questions like "why not just use RISC-V?" and "why does it support 256 registers?"
* [Differences to ARM & RISC-V](DifferencesToARMAndRISCV.md) should summarise how this fits in with existing ARM & RISC-V infrastructure
* [Licensing Explained](LicensingExplained.md) should clarify the intention and specifics of the (Public Domain!) license

## Tools

* [ZAsm](https://github.com/ZYSF/ZAsm/) a simple but flexible assembler which supports the new instruction set.
    - NOTE: This may be slightly out-of-sync with latest processor features.
* [ZLink](https://github.com/ZYSF/ZLink/) a linker which can produce flat binaries from the assembled code.
* A C compiler is also in development.
