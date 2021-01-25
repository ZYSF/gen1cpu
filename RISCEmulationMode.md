# RISC Emulation Mode

## Introduction

One issue with processor design is tooling; Imagine how much of a pain in the arse it would be to maintain a special fork of GCC and associated tools just to bootstrap a processor!

For this reason, I've started adding a RISC Emulation Mode designed to give partial hardware optimisation for running RISC-V binaries (while allowing the exact features to be determined by software extensions).

## Enabling RISC Emulation Mode

This can be done by setting a bit in the flags control register. You might want to enable "Overlord Mode" as well since this will allow you control over exactly which instructions are allowed (this means you can disable or reimplement instructions even if they are already defined in hardware).

Generally speaking, RISC Emulation Mode would be enabled in the context of a particular task, so you'd generally use the "mode switching" instructions similarly to switching between "native" tasks, except that some tasks may have RISC Emulation Mode enabled.

## RISC Emulation Without Hardware Acceleration

The basic system of enabling RISC Emulation mode allows you to trap any unimplemented RISC-V major opcodes (i.e. by implementing them in system mode using the native instruction set), but doesn't by itself offer any real advantage over a plain interpreter.

The advantage comes from the fact that the hardware, when running in this mode, may itself implement optimised versions of some (or, in a future implementation, perhaps even all) RISC-V instructions.

Initially this mode has been added without accelerated support for any instructions; Any RISC-V instruction (unless hardware support is added) will trigger an invalid instruction exception just like an unrecognised instruction when operating in a normal mode.

Assuming no such instructions are enabled in hardware, enabling RISC Emulation Mode will cause three things to change:

1. The zero register will become tied to the value zero; Any write to the register will be ignored and any read from the register will result in zero. (It's original value will still be maintained once you switch to another mode.)
2. The "major+minor opcode" portion of each instruction for the purposes of "overlord" mode will be the lower seven bits of the instruction (instead of the higher 8 bits outside of RISC Emulation Mode)
3. The usual decoding of instructions will be disabled (that is, unless RISC-V instructions are added are added in hardware, they will all be considered invalid instructions)

## Purpose & Limitations Of RISC Emulation Mode

Generally speaking, you should be able to implement a complete RISC-V compatible environment, but it would probably require a lot of work to implement things needed by operating systems.

So this mode can be made very general but it's purpose is mostly to:

1. Make it easier to bootstrap systems (you just need some assembler code to implement any missing instructions and then a RISC-V compiler toolchain)
2. Make it possible to run user-mode programs compiled for RISC-V

In particular, this mode doesn't (at least currently) make any attempt to emulate RISC-V hypervisor features or anything of that nature; It's just for emulating the instruction set itself, and it will generally still require some "native" instructions to access advanced functionality (even if all the common instructions are added to hardware in the future).

## Hardware-Accelerated Emulation

TODO (Not yet implemented).

The plan is essentially to add those instructions which are most critical for running C programs, while leaving more-specialised instructions (e.g. dealing with mode switching and so on) to be implemented in hardware.

In other words, the result would be similar to a microcode-based implementation of RISC-V, except that the microcode is just normal operating system code (if it doesn't need to do anything that special, it could potentially even be implemented using RISC-V instructions).