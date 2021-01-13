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

  OP_SYSCALL		8'h00	// 0x00??????: invalid instruction, but reserved for encoding system calls

### Addimm

  OP_ADDIMM			8'h11	// 0x11abiiii: a=b+i; // NOTE: Can only access lower 16 registers due to encoding
  
### Add

  OP_ADD				8'hA1	// 0xA1aabbcc: a=b+c; // NOTE: Encoding allows up to 256 registers, but higher ones might be disabled

### Sub

  OP_SUB				8'hA2	// 0xA2aabbcc: a=b-c;

### And

  OP_AND				8'hA3
  
### Or
  OP_OR				8'hA4

### Xor
  
  OP_XOR				8'hA5

### Shl (shift left)

  OP_SHL				8'hA6

### Shrz (shift right, with zero used for any assumed high bits)

  OP_SHRZ			8'hA7

### Shrs (shift right, with the sign bit used for any assumed high bits)

  OP_SHRS			8'hA8

### Blink (branch-link, stores the return address as the following instruction but doesn't do the actual branch)

  OP_BLINK			8'hB1	// 0xB1aaxxxx: a = pc + 4;

### Bto (branch-to, as in a simple goto using a register as the target)

  OP_BTO				8'hB2	// 0xB2xxxxcc: npc = c;

### Be (branch-enter, stores the return address and branch to somewhere)

  OP_BE				8'hB3 // 0xB3aaxxcc: a = pc + 4; npc = c; // This is short for branch-and-enter

### Before (this is basically the mode-switching routine)

  OP_BEFORE			8'hB4 // 0xB4xxxxxx: npc = before; nflags = mirrorflags; nmirrorflags = flags; nbefore = mirrorbefore; nmirrorbefore = before;

### Bait (enters a trap)

  OP_BAIT			8'hB8 // 0xB8xxxxxx: invalid instruction, but reserved for traps.

### Ctrlin64 (for co/processor info)

  OP_CTRLIN64		8'hC3	// 0xC3abiiii: a=ctrl[b+i];

### Ctrlout64 (for co/processor info)

  OP_CTRLOUT64		8'hCB	// 0xCBbciiii: ctrl[b+i]=c;

### Read32 (for memory)

  OP_READ32			8'hD2 // 0xD2abiiii: a=data[b+i];

### Write32 (for memory)

  OP_WRITE32		8'hDA	// 0xDAbciiii: data[b+i]=c;

### In32 (for I/O)

  OP_IN32			8'hE2	// 0xE2abiiii: a=ext[b+i];

### Out32 (for I/O)

  OP_OUT32			8'hEA	// 0xEAbciiii: ext[b+i]=c;

### Ifabove (for conditional branching comparing unsigned integers)

  OP_IFABOVE		8'hFA	// 0xFAbciiii: if((unsigned) b > (unsigned) c){npc = (pc & (-1 << 18)) | (i<<2);}

### Ifbelow (for conditional branching comparing signed integers)

  OP_IFBELOWS		8'hFB // 0xFBbciiii: if((signed) b < (signed) c){npc = (pc & (-1 << 18)) | (i<<2);}

### Ifequals (for conditional branching based on bit-equality)

  OP_IFEQUALS		8'hFE	// 0xFEbciiii: if(b == c){npc = pc + (i<<2);}

## Enhancements Which May Be Needed

* Particularly to run C programs smoothly, optimised 64-bit memory operations would be handy. In some other cases too there are common sequences which could be replaced with single instructions designed for those uses.
* Semantics of loading smaller values also need to be clarified (particularly at which points sign extension happens).
* For system code, an additional control register or two just for storing cached pointers (e.g. to the task structure) would be helpful.
* There are probably some other cases where common code sequences can be replaced with a single optimised instruction.
* Floating point support would be generally helpful (especially for porting C programs).
