# Addressing Modes

This document is intended to clarify the design of the memory, I/O, instruction and control-register addressing.

## Addressing Instructions

Instructions are always exactly 32 bits (4 bytes) in length (unless any e.g. compressed instruction modes are added in the future).

Instruction addresses are expected to be byte addresses (i.e. the address of an instruction is expected to always be a multiple of four, pointing to the first byte of that 4-byte instruction).

Instruction addresses, internally at least, are the same size as the internal registers (that is, 64 bits for the default implementation - or perhaps 32 bits for a smaller one).

This can obviously be wasteful or restrictive in a few cases (hence why some architectures support multiple instruction sizes), but it is helpful for a few reasons:

1. It's a convenient size for most instructions and we don't have to worry too much about running out of encoding space for adding new instructions
2. It makes it easy to determine the address of the current/next instruction with fewer edge-cases (e.g. you'll never get an exception from reading the second part of an instruction)
3. It's a convenient size for an internal memory bus (an 8-bit or 16-bit bus would be slow whereas a 64-bit bus would waste a lot of wires & logic most of the time)

## Addressing Memory

Memory addressing, at a minimum, is expected to work like instruction addressing: You can generally read or write any 32-bits from any 4-byte aligned byte address within valid memory.

At the hardware level, the bus interface does support options for larger/smaller sizes (and could also support unaligned access), however these interfaces are expected to be optional. Similarly, there is space in the instruction set encoding to add 1/2/8-byte memory access instructions, but these are not implemented by default.

The memory bus and instruction bus *might* be mapped to the same memory by the hardware, but this isn't necessarily the case (in the current implementation, they all share a single physical bus, but instruction fetches have a special marker).

This design has some advantages:

1. Your memory interface only needs to support aligned 32-bit access
2. Endianness is not significant at the hardware level (unless other-sized access is implemented at the hardware level, a little-endian or big-endian implementation would be indistinguishable or meaningless)
3. Instruction and data memory can be entirely separated (e.g. to limit runnable code to just a ROM), but for general usage they can conveniently fit into the same bus

The disadvantage is that you need to handle any 8/16/64-bit values in software rather than having a convenient instruction to read/write each one. For faster implementations, you'd probably at least want 8-bit and possibly 64-bit access, but these can be added cleanly on top of the existing implementation (as long as your external memory system supports it).

## Addressing I/O

I/O addressing works the same as memory addressing, but (similarly to instructions) the I/O bus can be mapped differently in hardware.

The main difference is that the I/O bus can only be accessed from system mode (although this restriction will probably become configurable in the future).

Implementations supporting multiple-sized memory can do the same for the I/O bus, or they might instead choose to keep it as a 32-bit bus and only implement the more complex instructions for memory addresses.

## Addressing Control Registers

Control registers (which are like special/internal memory for controlling core functions) have similar access instructions to normal memory or the I/O bus except:

1. They don't generally use registers to calculate the address (although that functionality might be re-added)
2. They're just numbered one-by-one, rather than using byte addresses
3. They're always the same size as the internal registers, so 64-bit by default (the effective size depends on the control register, but they are always treated as though they're the same size by instructions)
4. The memory management unit doesn't apply any translations to control registers
5. Like the I/O bus (but unlike memory or instructions) access to control registers is currently disabled entirely unless operating in system mode

## The Real-Time Memory Management Unit (MMU)

If the MMU is enabled, it will perform translations on instruction, memory and I/O addresses (but it will *not* translate any control register indices).

Aside from allowing you to create a "virtual address space" using your own locations instead of physical memory locations (for the sake of organisation), the MMU also allows you to restrict access to memory so that user-mode code can't access your system-mode data (or the data of other programs).

The MMU does _not_ perform any automatic cacheing or memory-based table lookup, it only operates with a limited table of mappings at a time, so it will always immediately match and/or immediately disqualify an address. Failure to match an address or an attempt to access a matched address the wrong way (e.g. fetching instructions from data-only memory) will trigger an appropriate exception and prevent any of that operation from reaching the external bus. For more complex setups, an operating system can keep it's own tables of accessible memory and map additional parts in and out (repeating any instructions referring to a valid-but-unmapped area after mapping that area).

The MMU includes the data size in it's calculations and is designed to be as accurate as reasonably possible, so (besides not being able to directly access addresses which intersect multiple regions) it shouldn't require any additional changes to allow e.g. unaligned or 64-bit operations.

The exact details of this configuration is described in [Control Registers](ControlRegisters.md).

