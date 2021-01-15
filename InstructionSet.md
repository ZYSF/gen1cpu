# Instruction Set

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

This encoding (which is shared for most other basic math operations) allows up to 256 registers, but higher ones might be disabled.

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

### Blink (branch-link, stores the return address as though branching but doesn't do the actual branch)

    OP_BLINK			0xB1
  
    0xB1aaxxxx: a = pc + 4;
  
This instruction can be used to get a basis for calculating code-relative addresses if necessary.

### Bto (branch-to, as in a simple goto using a register as the target)

    OP_BTO				0xB2
  
    0xB2xxxxcc: npc = c;

This instruction just branches to the location in the given register.

### Be (branch-enter, stores the return address and branch to somewhere)

    OP_BE				0xB3
  
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
  
Invalid instruction, but reserved for traps. That is, if a debugger replaces an instruction with a special one to trigger an exception back into the debugger, then it will probably be one of these instructions.

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

The standard memory bus allows for 64-bit addresses but only handles 32 bits of data at a time. When reading a value (into a 64-bit register), it is *not* sign-extended (TODO: Test this).

Implementations may provide specialised instructions and/or specialised hardware interfaces for dealing with other sizes, but as a standard 32-bit reads/writes are probably the most practical.

Implementations can also either ignore or raise errors if the higher/lower bits of the addresses are not what they expect, or more generally if the address is protected or just beyond memory (this generally means that read/write addresses should be multiples of four, and that any unused higher bits should be left as zero).

### Write32 (write data memory)

    OP_WRITE32		0xDA
  
    0xDAbciiii: data[b+i]=c;

### In32 (read I/O)

    OP_IN32			0xE2
  
    0xE2abiiii: a=ext[b+i];
  
The I/O bus operates *exactly* like the memory bus, except it's the I/O bus, and it can only be accessed from system-mode (unless an implementation has a special feature to expose part of it to user-mode).

In other words, it's just like a secondary channel of memory, except that it could be implemented entirely separately to memory so I/O devices can't overhear any memory stuff and memory devices can't overhear any I/O stuff.

This is also the case for the instruction bus (which would typically match the memory bus but not necessarily). For the sake of simplicity, the current interface shares a single set of data/address wires, but the design allows for more-secured or more-optimised implementations to bypass the normal "data memory" bus entirely for both code and I/O operations.

### Out32 (write I/O)

    OP_OUT32			0xEA
  
    0xEAbciiii: ext[b+i]=c;

### Ifabove (for conditional branching comparing unsigned integers)

    OP_IFABOVE		0xFA
  
    0xFAbciiii: if((unsigned) b > (unsigned) c){npc = (pc & (-1 << 18)) | (i<<2);}

Conditionals use the constant in a special way (TODO: This isn't handled properly in the assembler yet!). All 16 bits replace the third to eightenth bits of the existing program counter, meaning they can target anywhere within the same 256 kilobyte-aligned space.

### Ifbelows (for conditional branching comparing signed integers)

    OP_IFBELOWS		0xFB
  
    0xFBbciiii: if((signed) b < (signed) c){npc = (pc & (-1 << 18)) | (i<<2);}

### Ifequals (for conditional branching based on bit-equality)

    OP_IFEQUALS		0xFE
  
    0xFEbciiii: if(b == c){npc = (pc & (-1 << 18)) | (i<<2);}

This can also be used for unconditional jumps to local addresses (since any register always equals itself).

## Enhancements Which May Be Needed

* Particularly to run C programs smoothly, optimised 64-bit memory operations would be handy.
* Semantics of loading smaller values also need to be clarified (particularly at which points sign extension happens).
* For system code, an additional control register or two just for storing cached pointers (e.g. to the task structure) would be helpful.
* There are probably some other cases where common code sequences can be replaced with a single optimised instruction.
* Floating point support would be generally helpful (especially for porting C programs).
