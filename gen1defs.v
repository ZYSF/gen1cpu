`timescale 1ns / 1ps

/* Word-sized (instruction-sized) addressing can be used for embedded cases but generally instructions are addressed in bytes.
 * This basically determines whether the program counter is incremented by 1 (as in 1 instruction) or by 4 (as in 4 bytes), but
 * there are also a number of edge cases. Jump targets embedded in instructions generally translate to the same target either way,
 * since the bits of the target are decoded into the appropriate bits of the program counter either way (you can only jump to
 * addresses on 4-byte boundaries with the immediate jump).
 */
//`define GEN1_WORDADDR
`ifdef GEN1_WORDADDR
//`define GEN1_INSTRINCR 1
`else
`define GEN1_BYTEADDR
//`define GEN1_INSTRINCR 4
`endif

`define GEN1_INT64
/* 64-bit mode is enabled with GEN1_INT64, otherwise 32-bit mode is implied. This changes the internal registers (including some
 * special registers like flags), as well as the ALU, the program counter and the external bus.
 */
`ifdef GEN1_INT64
`else
`define GEN1_INT32
`endif
