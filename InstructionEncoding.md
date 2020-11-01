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

### Instructions

## Syscall

  OP_SYSCALL		8'h00	// 0x00??????: invalid instruction, but reserved for encoding system calls

## Addimm

  OP_ADDIMM			8'h11	// 0x11abiiii: a=b+i; // NOTE: Can only access lower 16 registers due to encoding
## Add

  OP_ADD				8'hA1	// 0xA1aabbcc: a=b+c; // NOTE: Encoding allows up to 256 registers, but higher ones might be disabled

## Sub

  OP_SUB				8'hA2	// 0xA2aabbcc: a=b-c;

## And

  OP_AND				8'hA3
  
## Etc...
  OP_OR				8'hA4
  OP_XOR				8'hA5
  OP_SHL				8'hA6
  OP_SHRZ			8'hA7
  OP_SHRS			8'hA8
  OP_BLINK			8'hB1	// 0xB1aaxxxx: a = pc + 4;
  OP_BTO				8'hB2	// 0xB2xxxxcc: npc = c;
  OP_BE				8'hB3 // 0xB3aaxxcc: a = pc + 4; npc = c; // This is short for branch-and-enter
  OP_BEFORE			8'hB4 // 0xB4xxxxxx: npc = before; nflags = mirrorflags; nmirrorflags = flags; nbefore = mirrorbefore; nmirrorbefore = before;
  OP_BAIT			8'hB8 // 0xB8xxxxxx: invalid instruction, but reserved for traps.
  OP_CTRLIN64		8'hC3	// 0xC3abiiii: a=ctrl[b+i];
  OP_CTRLOUT64		8'hCB	// 0xCBbciiii: ctrl[b+i]=c;
  OP_READ32			8'hD2 // 0xD2abiiii: a=data[b+i];
  OP_WRITE32		8'hDA	// 0xDAbciiii: data[b+i]=c;
  OP_IN32			8'hE2	// 0xE2abiiii: a=ext[b+i];
  OP_OUT32			8'hEA	// 0xEAbciiii: ext[b+i]=c;
  OP_IFABOVE		8'hFA	// 0xFAbciiii: if((unsigned) b > (unsigned) c){npc = (pc & (-1 << 18)) | (i<<2);}
  OP_IFBELOWS		8'hFB // 0xFBbciiii: if((signed) b < (signed) c){npc = (pc & (-1 << 18)) | (i<<2);}
  OP_IFEQUALS		8'hFE	// 0xFEbciiii: if(b == c){npc = pc + (i<<2);}
