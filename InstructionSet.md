# Instruction Set

## Basic Design

Hopefull the instructions here should be just enough (but not too much) to start getting complex software running. Beyond that, there are a lot of optimisations and customisations which could be made (ideally within the framework of the core design).

The instruction set has a few similarities to RISC-like designs (such as MIPS, ARM or RISC-V):

* There isn't a special instruction for everything, everything's based on a more generalised set of instructions (this means some kinds of instructions often have some obscure secondary uses)
* Instructions are stored in a somewhat-simplified and categorical format (i.e. each instruction is the same size)
* Particularly inefficient or error-prone things like memory access are (ideally) limited to only a few instructions

But there are also some differences:

* The instructions don't imply any kind of uniform timing constraints (in other words, more complex/compound instructions can be added provided that they follow exception-handling constraints)
* Stability and extensibility are prioritised over efficiency
* The standard instructions rarely have complex/optimised options (or when they do, they're usually organised as specific sub-operations rather than e.g. as flags)
* Instruction parts are aligned to hex-friendly borders (instead of using e.g. 3 bits for this and 9 bits for that, almost everything is 4/8/16-bits)
* Register encoding is not perfectly uniform (instead of allowing e.g. 32 general-purpose registers everywhere, we allow up to 256 for some operations but only 16 for others)
* *Plenty* of space has been intentionally left for customised instructions
* Mode-switching functionality and timers are part of the core design (that is, it's a minimalist instruction set but not necessarily a minimalist platform)

And some implications:

* The encoded instructions are easier to decode by humans (e.g. in the course of debugging some program), for example (in hex format) the generalised ALU operations all start with an `A`.
* Because instructions don't have complex options and decode to conveniently-sized parts, it can be more-efficiently emulated on other devices 
* The ability to address up to 256 registers (on an ideal implementation) is perfect for when you need to do a whole bunch of cryptography without any RAM or MMU or cache circuitry spying on you

## Encoding

Instructions are generally categorised by the highest nibble with the nibble below that
usually being an ALU operation or other sub-instruction. For example, to add registers you'd use 0xA1 (ALU op #1)
whereas to add an immediate value you'd use the same ALU subcode but the immediate supercode: 0x11 (immediate op #1).

These categories aren't a hard-and-fast rule, future processors may condense additional instructions into
unused opcodes regardless of categories, but it is designed to make recognising and producing the basic
instructions easier for humans.

For this same reason, opcodes and operands are generally aligned on 4- or
8-bit boundaries, so e.g. register #3 either looks like "3" or "03" in hex (depending on whether it's in a
4-bit or 8-bit operand). This encoding allows for addressing up to 256 different registers in most instructions
and up to 16 in instructions with more bits reserved for immediate values.

## Instructions

### Syscall

  OP_SYSCALL		0x00

  0x00??????: ???

Invalid instruction, but reserved for encoding system calls.

### Addimm

  OP_ADDIMM			0x11
  
  0x11abiiii: a=b+i;

NOTE: Can only access lower 16 registers due to encoding.
  
### Add

  OP_ADD				0xhA1
  
  0xA1aabbcc: a=b+c;

NOTE: Encoding allows up to 256 registers, but higher ones might be disabled.

### Sub

  OP_SUB				0xA2
  
  0xA2aabbcc: a=b-c;

### And

  OP_AND				0xhA3
  
### Or
  OP_OR				0xA4

### Xor
  
  OP_XOR				0xA5

### Shl (shift left)

  OP_SHL				0xA6

### Shrz (shift right, with zero used for any assumed high bits)

  OP_SHRZ			0xA7

### Shrs (shift right, with the sign bit used for any assumed high bits)

  OP_SHRS			0xA8

### Blink (branch-link, stores the return address as the following instruction but doesn't do the actual branch)

  OP_BLINK			0xB1
  
  0xB1aaxxxx: a = pc + 4;
  
This instruction can be used to calculate code-relative addresses if necessary.

### Bto (branch-to, as in a simple goto using a register as the target)

  OP_BTO				0xB2
  
  0xB2xxxxcc: npc = c;

### Be (branch-enter, stores the return address and branch to somewhere)

  OP_BE				8'hB3
  
  0xB3aaxxcc: a = pc + 4; npc = c;

This is short for branch-and-enter.

### Before (for explicit mode-switching)

  OP_BEFORE			0xB4
  
  0xB4xxxxxx: npc = before; nflags = mirrorflags; nmirrorflags = flags; nbefore = mirrorbefore; nmirrorbefore = before;

Mode-switching (whether explicit or caused by an exception or interrupt) mostly involves swapping out some important context information for mirror copies. That is, the code which is currently running has it's own copy, and when the mode is switched, some different code starts executing with a different copy of the context information.

The important part here is that we're never left in-between contexts or part-way-through an instruction (the switching itself all happens within the space of one instruction, whether under explicit or exceptional circumstances). The switching should do just enough to allow a control routine to handle the situation properly (or just enough to return control back to the normal program) but shouldn't do too much that it becomes inefficient (for example, there's no need to automatically save/restore all the general-purpose registers).

### Bait (enters a trap)

  OP_BAIT			0xB8
  
  0xB8xxxxxx: ???
  
Invalid instruction, but reserved for traps.

### Ctrlin64 (read co/processor info)

  OP_CTRLIN64		0xC3
  
  0xC3abiiii: a=ctrl[b+i];

Control registers (which are used for internal circuits like the timer) are accessed similarly to the memory interface, except that the size of values always corresponds to the internal register size and control registers are indexed counting in 1 rather than word sizes (ensuring there is never any ambiguity about the basic operations).

### Ctrlout64 (read co/processor info)

  OP_CTRLOUT64		0xCB
  
  0xCBbciiii: ctrl[b+i]=c;

### Read32 (read data memory)

  OP_READ32			0xD2
  
  0xD2abiiii: a=data[b+i];

The standard memory bus allows for 64-bit addresses but only handles 32 bits of data at a time.

Implementations may provide specialised instructions and/or specialised hardware interfaces for dealing with other sizes, but as a standard 32-bit reads/writes are probably the most practical.

Implementations can also either ignore or raise errors if the higher/lower bits of the addresses are not what they expect, or more generally if the address is protected or just beyond memory (this generally means that read/write addresses should be multiples of four, and that any unused higher bits should be left as zero).

### Write32 (write data memory)

  OP_WRITE32		0xDA
  
  0xDAbciiii: data[b+i]=c;

### In32 (read I/O)

  OP_IN32			0xE2
  
  0xE2abiiii: a=ext[b+i];
  
The I/O bus operates *exactly* like the memory bus, except it's the I/O bus.

In other words, it's just like a secondary channel of memory, except that it could be implemented entirely separately to memory so I/O devices can't overhear any memory stuff and memory devices can't overhear any I/O stuff.

This is also the case for the instruction bus (which would typically match the memory bus but not necessarily). For the sake of simplicity, the current interface shares a single set of data/address wires, but the design allows for more-secured or more-optimised implementations to bypass the normal "data memory" bus entirely for both code and I/O operations.

### Out32 (write I/O)

  OP_OUT32			0xEA
  
  0xEAbciiii: ext[b+i]=c;

### Ifabove (for conditional branching comparing unsigned integers)

  OP_IFABOVE		0xFA
  
  0xFAbciiii: if((unsigned) b > (unsigned) c){npc = (pc & (-1 << 18)) | (i<<2);}

### Ifbelow (for conditional branching comparing signed integers)

  OP_IFBELOWS		0xFB
  
  0xFBbciiii: if((signed) b < (signed) c){npc = (pc & (-1 << 18)) | (i<<2);}

### Ifequals (for conditional branching based on bit-equality)

  OP_IFEQUALS		0xFE
  
  0xFEbciiii: if(b == c){npc = pc + (i<<2);}

## Enhancements Which May Be Needed

* Particularly to run C programs smoothly, optimised 64-bit memory operations would be handy. In some other cases too there are common sequences which could be replaced with single instructions designed for those uses.
* Semantics of loading smaller values also need to be clarified (particularly at which points sign extension happens).
* For system code, an additional control register or two just for storing cached pointers (e.g. to the task structure) would be helpful.
* There are probably some other cases where common code sequences can be replaced with a single optimised instruction.
* Floating point support would be generally helpful (especially for porting C programs).
