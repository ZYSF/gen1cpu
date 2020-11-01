# gen1cpu
Finally, a CPU that isn't mind-numbingly complex. (Compilers and documentation sold separately.)

Implemented in Verilog and featuring an independently-designed instruction set (completely copyright-free!).

EDIT: I initially uploaded some of the earlier version instead of the current version. Disregard the first commits (those probably aren't in a usable state and don't reflect my own work).

## Design

### Issues with other platforms

I originally was a bit confused by RISC-V, since it seems to be slowly taking over the world but (looking at the specs) it seemed a bit half-baked and unfinished, so I started looking for alternatives to use in robotics. I'm frankly kind of surprised anyone managed to port operating systems to it because I just didn't see a clear structure for that kind of stuff (it's probably starting to mature now, but I guess the buzz just started way before the ISA was finalised).

In any case, RISC-V seems to be the kind of system that mostly only makes sense to hardcore RISC idealists, who are typically absent from real-world engineering discussions (one example is the use of a hardcoded zero register - it "makes sense" in the context of RISC ideals, but it just doesn't make sense from a design perspective - registers and constants are totally different ideas and should never be mixed up!). So, I'm not trying to discount it's relevance for teaching CPU concepts (and - possibly - it's relevance in efficient real-world chips), but it didn't seem to be what I was looking for as a stable and future-proof platform for robotics projects.

ARM has always been a pain in the arse (the peripheral ABIs are horrendous, the tools are terrible, etc.), x86 is an absolute mess of half-working backwards compatibility features, both appear to have ongoing security issues, and alternatives like MIPS, POWER and SPARC seem to basically be dead or unclearly-specified and unclearly-licensed. All are over-optimised for running 90's code and the 64-bit versions are probably all a bit hacky as a result (too many legacy/compatibility features, too many ABI versions, too many tool options, etc.).

Conventional embedded chips like those used in Arduinos are fine (or at least the Arduino SDK solves many of the chip-specific problems), but the more robust chips can't really run large/modern programs and for lower-level code they typically face similar problems as other alternatives.

### A New Instruction Set

So, I decided a simpler solution was required. Initially I hired a third-party developer who was familiar with MIPS to design a simple CPU core, and the developer completed this with minimal issues. I knew MIPS wouldn't be sufficient, especially since most versions of the instruction set aren't open-source, but I managed to use what I'd learnt from working with this developer's implementation to develop a CPU for my own instruction set. My implementation isn't nearly as fast as the original but is also designed to nicely handle edge cases such as hardware interrupts, bus errors and invalid instructions.

The new instruction set is still somewhat similar to MIPS/RISC-V/ARM but not as "clever" in it's encoding, which makes developing tools and bootstrapping implementations a little easier and should also avoid infringing on any patents for such cleverness. Luckily, computers don't need to be very clever (unless you need to suck up to investors), and instruction-level optimisations aren't critical to modern use cases (unless you need to convince someone they are in order to sell a product, in which case I'll charge a flat rate of $1000 for each clever extension).

### Future Plans

Alongside this I've also been working on some compilers and other tools like an assembler and a linker, but these still aren't quite usable yet (or at least don't fit together as a set yet) and some of them will probably need to be rewritten for release. So there's a bit more of an ecosystem than just the CPU, at least in prototype form, but as to whether it will all come together as a usable platform in the future I can't give any guarantees yet.

## Features

* Basic integer maths
* Basic control flow (decision-making, looping and function calls)
* Basic system-/user-mode functionality, complete with mode switching, invalid-instruction handling and interrupt handling
* Built-in timer peripheral (so multitasking can be implemented without any additional peripherals)
* Very lightweight (can fit into very cheap FPGAs and small 32-bit builds should be similar size to the smaller RISC-V cores)
* Custom instruction set with no proprietary tricks (as far as I know I haven't infringed on any patents or anything, and the code is PUBLIC DOMAIN)
* Supports both 32-bit and 64-bit builds (instructions are always 32 bits but integer and memory operations are flexible)
* Supports up to 256 general-purpose registers, with up to 16 being accessible in instructions with limited space (most reasonable implementations would only want between about 8 and 32 registers, but allowing special implementations to use a special number can't hurt. In the future, operating systems might support emulating different numbers of registers too, so allowing implementations to change the number only influences efficiency not ABI compatibility.)
* Some wrappers for fitting it into a single memory bus (basic build assumes code and data buses are distinct)

## Code Overview

* The CPU itself is defined entirely in `SimpleCore.v`
* The `SimpleMCU.v` module is a simple top-level implementation for an FPGA with a few LED outputs and one clock input, this will just run some simple instructions and blink the LEDs

## Lacking

* Documentation
* Tools
* Optimisations (most/all instructions take more cycles than should be strictly necessary)
* Test cases (I have done some ad-hoc testing with Icarus Verilog and also on FPGA, but only the FPGA module is included as the other was mostly trash)
* etc.
