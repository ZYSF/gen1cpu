# Differences to ARM & RISC-V

## Design

Both ARM and RISC-V are designed to be efficient, general-purpose RISC-based processors.

This processor follows some of the same RISC design principles (for example instructions are all the same size) but the focus is on *security* instead of efficiency.

## Security Features

Some implementations of ARM and RISC-V come with comparable security features to this processor (in particular, memory protection and special user-mode and system-mode switching).

The primary difference with this processor is that the security features are an integral part of the design. This means there is no standard version of the processor without those features, and it also means those features are well-documented and not fragmented.

## Efficiency/Performance Features

The instruction sets are comparable, so features such as cacheing, pipelining and compressed instructions could be added regardless of options. Similarly to ARM and RISC-V designs, these features are not an integral part of the design but would be expected to be added by vendors focusing on efficient implementations.

Optimised implementations of ARM and RISC-V are of course more mature, so if efficiency was the only concern these would have obvious advantages over this processor.

## Licensing

This processor is most comparable to RISC-V in terms of licensing, and completely in opposition to ARM's licensing model. That is, if you choose ARM, you're stuck with a sinking ship and will eventually need to buy a new one. If you choose RISC-V (or this processor design) then you can always hire someone to fix any flaws you find in it.

Compared to RISC-V the licensing of this processor design is slightly less restrictive, but only marginally so (I reserve no copyright whatsoever, whereas RISC-V might require a third-party copyright notice). In both cases, third-party vendors may choose to offer commercialised versions of the design but are generally unable to force anyone else to abandon their competing version (whereas with ARM, commercial rights belong exclusively to their partners).

## Implementation Quality

The implementation quality of this processor is far lower than that of ARM or RISC-V (as should be expected since those have been in development for a lot longer).

The quality will be comparable once sufficient testing has been performed (I wouldn't recommend using it in any critical [life-or-death] devices at this point, but after sufficient testing it should be a prime candidate for such devices).

## Documentation/Specification Quality

Unless anyone can explain clearly how mode switching, exception handling and memory protection work in ARM or RISC-V without using a whole bunch of model numbers and other jargon, I'm going to say mine's significantly better.

## Programming Model

The programming model is comparable between all three; For example it would be possible to port Unix-like operating systems to any processor with comparable features.

This processor is differentiated by having it's own binary toolchain (assembler, linker & intermediate format) whereas others tend to use ports of the (often quite glitchy) GNU toolchain. For the purposes of porting software (particularly C/C++ programs and Unix) a port of the GNU toolchain would be inevitable, but having specialised tools can dramatically simplify bootstrapping (e.g. I don't have to rely on any obscure methods to create flat binary files for ROMS).

I plan to release higher-level tools to reduce the focus on C/C++ (which are a pain in the arse for secure software). It's likely that these tools would be ported to other platforms too, but may benefit from enhanced support on this processor.

Some implementations of other processors (including at least some ARM devices) benefit from the popular Arduino frontend. This may be a high priority for support once microcontroller versions of the processor are released.
