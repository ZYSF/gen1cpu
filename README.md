# gen1cpu
Finally, a CPU that isn't mind-numbingly complex. (Compilers and documentation sold separately.)

## Features

* Basic integer maths
* Basic control flow (decision-making, looping and function calls)
* Basic system-/user-mode functionality, complete with mode switching and interrupt handling
* Very lightweight (can fit into very cheap FPGAs and small 32-bit builds should be similar size to the smaller RISC-V cores)
* Custom instruction set with no proprietary tricks (as far as I know I haven't infringed on any patents or anything, and the code is PUBLIC DOMAIN)
* Supports both 32-bit and 64-bit builds (instructions are always 32 bits but integer and memory operations are flexible)
* Some wrappers for fitting it into a single memory bus (basic build assumes code and data buses are distinct)

## Code Overview

* The CPU itself is defined almost entirely in `gen1.v`
* Some definitions and configuration is defined in `gen1defs.v`
* The `gen1vn.v` module is a wrapper which organises both the memory buses into a single bus ("Von-Neumann" style)
* The `gen1vn8.v` module wraps gen1vn into single-byte memory operations (which can particularly make testing easier because a lot less pins are required)
* The `gen1demo8.v` module is a simple top-level implementation for an FPGA with a few LED outputs and one clock input, this will just run some simple instructions and blink the LEDs

## Lacking

* Documentation
* Tools
* Optimisations (most/all instructions take more cycles than should be strictly necessary)
* Test cases (I have done some ad-hoc testing with Icarus Verilog and also on FPGA, but only the FPGA module is included as the other was mostly trash)
* etc.
