/* Basic opcodes.
 *
 * IMPORTANT NOTE:
 *
 * In the descriptions, "a" represents the target register (and is only used where a general purpose register
 * is written to), "b" and "c" represent the source registers and "i" represents an immediate value. "?" is
 * used as a wildcard in situations where any value matches the description.
 *
 * ENCODING STYLE:
 *
 * Instructions are generally categorised by the highest nibble with the nibble below that
 * usually being an ALU operation or other sub-instruction. For example, to add registers you'd use 0xA1 (ALU op #1)
 * whereas to add an immediate value you'd use the same ALU subcode but the immediate supercode: 0x11 (immediate op #1).
 *
 * These categories aren't a hard-and-fast rule, future processors may condense additional instructions into
 * unused opcodes regardless of categories, but it is designed to make recognising and producing the basic
 * instructions easier for humans.
 *
 * For this same reason, opcodes and operands are generally aligned on 4- or
 * 8-bit boundaries, so e.g. register #3 either looks like "3" or "03" in hex (depending on whether it's in a
 * 4-bit or 8-bit operand). This encoding allows for addressing up to 256 different registers in most instructions
 * and up to 16 in instructions with more bits reserved for immediate values.
 *
 * Immediate values are always stored in the lower 16 bits of an instruction and are always sign-extended (whether
 * or not that's important depends on the instruction and context).
 *
 * BRANCHING & IF INSTRUCTIONS:
 *
 * Originally I planned to use a combined instruction for all jumps and then optimised variants. However, I settled
 * on a slightly-more-complicated but slightly-more-practical scheme: Jumps are separated into "branches", which
 * generally represent function call/return operations (or simplified jump-to-address or get-program-counter variants),
 * and "ifs", which only perform a simple jump to a nearby address but can also perform conditional jumps based on an
 * ALU operation (to perform an unconditional jump, you can just use an operation that would always evaluate to true).
 *
 * A variant of the "branch" set of instructions is also used to return from system mode after a system call or other
 * exception. That functionality is much more specialised than the other branch instructions, but essentially does
 * the same thing except using system registers instead of the normal register locations (but importantly, it also
 * switches the system flags and is only accessible if system mode is already enabled in the flags).
 *
 * MEMORY, CONTROL & I/O INSTRUCTIONS:
 *
 * For read/write operations (whether on data, control or extended I/O channels) the supercode represents
 * the bus (0xC? for Control, 0xD for Data or 0xE for Extensions) whereas the subcode holds the write bit
 * and the size order: 0xD2 doesn't have the high bit of the low nibble set, so it's a read, whereas 0xDA
 * does so it would be a write. The lowest two bits (or the whole low nibble if it's a read) determine the
 * size: 0 for a single byte, 1 for 16 bits, 2 for 32 bits, 3 for 64 bits.
 *
 * 0x2? instructions are reserved for optimised/immediate jumps, 0x3? instructions are reserved for optimised
 * loads.
 *
 * Currently, all of the control and I/O family of instructions are limited to access from system mode, however in the
 * future they may be configurable for user-mode operation as well (e.g. by only allowing low locations and using a
 * configurable bitmask to enable/disable access).
 *
 * The I/O bus is essentially meant to just be a redundant extra memory bus. It could either be used to access a
 * specific bus for external hardware devices (separate to normal memory) or it could be ignored or just used
 * to bypass MMU or (perhaps most importantly) just for debugging designs. Designs without an I/O bus can
 * just treat I/O instructions as invalid instructions and let the system software decide how to handle them.
 *
 * EXCEPTIONS & INTERRUPTS:
 *
 * The current exception-handling system tracks a last-exception-number value in a read-only control register.
 * A number of internal exceptions are supported (e.g. bad instruction) as well as a simple timer countdown alarm
 * run from the core's clock and a single external interrupt line with an acknowledge pin (the expectation being
 * that if the device needs multiple hardware interrupts it should probably have it's own mechanisms to prioritise
 * and describe the different kinds).
 *
 * Exception-handling behaviour is to swap the flags and xaddr registers with mirrorflags and mirrorxaddr, jumping to
 * the original xaddr and setting the new mirrorxaddr to the interrupted instruction. (TODO: Test/check/dwell upon this
 * behaviour.) Generally speaking, the system software must set up the flags and mirrorflags so that exceptions are
 * disabled while it's performing any sensitive operations that can't be interrupted but enabled while running any
 * code which needs to be debugged or otherwise monitored.
 *
 * Besides which registers are used, the most important semantics are that the interrupted instruction *wasn't
 * executed yet*, and the saved address points to that specific instruction (not to the one before or after it).
 * One notable edge case is that if an instruction jumps to an invalid memory address, an exception will be
 * triggered when landing at the invalid address. In that case, the system software must take extra care not to
 * try and read that instruction or return to that address. (This is called a bad dog exception because it won't
 * fetch and you have to be careful.)
 *
 * All unrecognised instructions should trigger a recoverable decoding exception.
 */
`define ENCODING_BAD			2'b00		// 0xop??????
`define ENCODING_OPABC		2'b10		// 0xopaabbcc
`define ENCODING_OPABI		2'b11		// 0xopabiiii
`define ENCODING_OPBCI		2'b01		// 0xopbciiii NOTE: Similar to OPABI encoding except two input registers
 
`define OP_SYSCALL		8'h00	// 0x00??????: invalid instruction, but reserved for encoding system calls
`define OP_ADDIMM			8'h11	// 0x11abiiii: a=b+i; // NOTE: Can only access lower 16 registers due to encoding
`define OP_ADD				8'hA1	// 0xA1aabbcc: a=b+c; // NOTE: Encoding allows up to 256 registers, but higher ones might be disabled
`define OP_SUB				8'hA2	// 0xA2aabbcc: a=b-c;
`define OP_AND				8'hA3
`define OP_OR				8'hA4
`define OP_XOR				8'hA5
`define OP_SHL				8'hA6
`define OP_SHRZ			8'hA7
`define OP_SHRS			8'hA8
`define OP_BLINK			8'hB1	// 0xB1aaxxxx: a = pc + 4;
`define OP_BTO				8'hB2	// 0xB2xxxxcc: npc = c;
`define OP_BE				8'hB3 // 0xB3aaxxcc: a = pc + 4; npc = c; // This is short for branch-and-enter
`define OP_BEFORE			8'hB4 // 0xB4xxxxxx: npc = before; nflags = mirrorflags; nmirrorflags = flags; nbefore = mirrorbefore; nmirrorbefore = before;
`define OP_BAIT			8'hB8 // 0xB8xxxxxx: invalid instruction, but reserved for traps.
`define OP_CTRLIN64		8'hC3	// 0xC3abiiii: a=ctrl[b+i];
`define OP_CTRLOUT64		8'hCB	// 0xCBbciiii: ctrl[b+i]=c;
`define OP_READ32			8'hD2 // 0xD2abiiii: a=data[b+i];
`define OP_WRITE32		8'hDA	// 0xDAbciiii: data[b+i]=c;
`define OP_IN32			8'hE2	// 0xE2abiiii: a=ext[b+i];
`define OP_OUT32			8'hEA	// 0xEAbciiii: ext[b+i]=c;
`define OP_IFABOVE		8'hFA	// 0xFAbciiii: if((unsigned) b > (unsigned) c){npc = (pc & (-1 << 18)) | (i<<2);}
`define OP_IFBELOWS		8'hFB // 0xFBbciiii: if((signed) b < (signed) c){npc = (pc & (-1 << 18)) | (i<<2);}
`define OP_IFEQUALS		8'hFE	// 0xFEbciiii: if(b == c){npc = pc + (i<<2);}

// Earlier design with combined branch/if instruction (decided to combine system-return function with branch instead)
//`define OP_BRIF			8'hBF	// 0xBFaabbcc: if(b != 0){a = pc + 4; nflags = mirrorflags; nmirrorflags = flags; npc = c;}

`define ALU_NOP			4'h0
`define ALU_ADD			4'h1
`define ALU_SUB			4'h2
`define ALU_AND			4'h3
`define ALU_OR				4'h4
`define ALU_XOR			4'h5
`define ALU_SHL			4'h6
`define ALU_SHRZ			4'h7
`define ALU_SHRS			4'h8
`define ALU_MULS			4'h9
`define ALU_ABOVE			4'hA
`define ALU_BELOWS		4'hB
`define ALU_CRUMBS		4'hC
`define ALU_DIVS			4'hD
`define ALU_EQUALS		4'hE

`define CTRL_CPUID			4'h0
`define CTRL_EXCN				4'h1
`define CTRL_FLAGS			4'h2
`define CTRL_MIRRORFLAGS	4'h3
`define CTRL_XADDR			4'h4
`define CTRL_MIRRORXADDR	4'h5
`define CTRL_TIMER			4'h6

`define EXCN_BADDOG			1		// Unable to fetch instruction (i.e. bad instruction address or fatal bus error)
`define EXCN_INVALIDINSTR	2		// Instruction was fetched but not recognised as valid by the decoder
`define EXCN_SYSMODEINSTR	3		// Instruction was fetched and could presumably be decoded, but requires system mode and was run in user mode
`define EXCN_BUSERROR		4		// The instruction was fetched/decoded but the memory or extension I/O triggered a bus exception
`define EXCN_REGISTERERROR	6		// The instruction was fetched/decoded but referred to a register which was unimplemented or blocked
`define EXCN_ALUERROR		7		// The instruction was fetched/decoded but the ALU operation triggered an error (e.g. bad operation or division by zero)
`define EXCN_RESERVED		8		// This exception number is reserved for system calls (which would currently trigger an EXCN_INVALIDINSTR)
`define EXCN_DINGDONG		9		// This exception is triggered by the internal timer unit (if enabled) i.e. for multitasking or other regular checks
`define EXCN_HARDWARE		10		//	This exception is triggered by external hardware, typically an interrupt controller (which should have it's own mechanism for interrupt numbers)

`define STAGE_INITIAL	0
`define STAGE_FETCH		1
`define STAGE_DECODE		2
`define STAGE_SETBUS		3
`define STAGE_GETBUS		4
`define STAGE_SAVE		5
`define STAGE_CLEANUP	6
`define STAGE_DECODEHACK 7
//`define STAGE_EXECUTE	3
//`define STAGE_RW1			4

`define STAGE_NOTREADY	8

`define STAGE_EXCEPTION	16
`define STAGE_XACK		17
`define STAGE_XWAIT		18

`define STAGE_ERROR		32

`define FLAGS_INITIAL			64'h0000000000000001
`define MIRRORFLAGS_INITIAL	64'h0000000000000001
/* Defines the value of the CPUID register, which should identify basic features/version as well as a vendor id.
 * Low byte is the maximum addressable register, next is ISA version, high bytes are a signature.
 */
`define CPUIDVALUE				64'h5A59534600000107

module SimpleDecoder(/*decodeclk, */ins, isregalu, isimmalu, isvalid, issystem, regA, regB, regC, regwrite, aluop, imm, valsize, ctrlread, ctrlwrite, dataread, datawrite, extnread, extnwrite, getpc, setpc, blink, bto, bswitch, bif);
//input decodeclk;
input [31:0] ins;
output reg isregalu;
output reg isimmalu;
output reg isvalid;
output reg issystem;
output wire [7:0]regA;
output wire [7:0]regB;
output wire [7:0]regC;
output reg regwrite;
output reg [3:0]aluop;
output [63:0]imm;
output reg [1:0]valsize;
output reg ctrlread;
output reg ctrlwrite;
output reg dataread;
output reg datawrite;
output reg extnread;
output reg extnwrite;
output reg getpc;
output reg setpc;
output reg blink;
output reg bto;
output reg bswitch;
output reg bif;

reg [1:0]encoding = 0;

wire [7:0]opcode = ins[31:24];

/* The immediate output is just the sign-extended version of the lower half of the instruction. It will produce output
 * regardless of whether the immediate is used by the instruction.
 */
wire [47:0]ext = ins[15] ? 48'b111111111111111111111111111111111111111111111111 : 0;
assign imm = {ext, ins[15:0]};

/* The registers are easy to decode in ABC-format instructions but need some specialisation/defaults for others. */
assign regA = (encoding == `ENCODING_OPABC) ? ins[23:16] : ((encoding == `ENCODING_OPABI) ? ins[23:20] : 0);
assign regB = (encoding == `ENCODING_OPABC) ? ins[15:8] : ((encoding == `ENCODING_OPABI) ? ins[19:16] : ((encoding == `ENCODING_OPBCI) ? ins[23:20] : 0));
assign regC = (encoding == `ENCODING_OPABC) ? ins[7:0] : ((encoding == `ENCODING_OPBCI) ? ins[19:16] : 0);

always @(opcode /*posedge decodeclk*/) begin
	case (opcode)
		`OP_ADDIMM: begin
			encoding = `ENCODING_OPABI;
			isimmalu = 1;
			isvalid = 1;
			regwrite = 1;
			aluop = `ALU_ADD; //[7:0] = {4'b0000:opcode[3:0]};
			
			isregalu = 0;
			//isimmalu = 0;
			//isvalid = 0;
			issystem = 0;
			//regwrite = 0;
			//aluop = 0;
			valsize = 0;
			ctrlread = 0;
			ctrlwrite = 0;
			dataread = 0;
			datawrite = 0;
			extnread = 0;
			extnwrite = 0;
			getpc = 0;
			setpc = 0;
			blink = 0;
			bto = 0;
			bif = 0;
			//encoding = 0;
			bswitch = 0;
		end
		`OP_ADD: begin
			encoding = `ENCODING_OPABC;
			isregalu = 1;
			isvalid = 1;
			regwrite = 1;
			aluop = `ALU_ADD; //[7:0] = {4'b0000:opcode[3:0]};
			
			//isregalu = 0;
			isimmalu = 0;
			//isvalid = 0;
			issystem = 0;
			//regwrite = 0;
			//aluop = 0;
			valsize = 0;
			ctrlread = 0;
			ctrlwrite = 0;
			dataread = 0;
			datawrite = 0;
			extnread = 0;
			extnwrite = 0;
			getpc = 0;
			setpc = 0;
			blink = 0;
			bto = 0;
			bif = 0;
			//encoding = 0;
			bswitch = 0;
		end
		`OP_SUB: begin
			encoding = `ENCODING_OPABC;
			isregalu = 1;
			isvalid = 1;
			regwrite = 1;
			aluop = `ALU_SUB; //[7:0] = {4'b0000:opcode[3:0]};
			
			//isregalu = 0;
			isimmalu = 0;
			//isvalid = 0;
			issystem = 0;
			//regwrite = 0;
			//aluop = 0;
			valsize = 0;
			ctrlread = 0;
			ctrlwrite = 0;
			dataread = 0;
			datawrite = 0;
			extnread = 0;
			extnwrite = 0;
			getpc = 0;
			setpc = 0;
			blink = 0;
			bto = 0;
			bif = 0;
			//encoding = 0;
			bswitch = 0;
		end
		`OP_AND: begin
			encoding = `ENCODING_OPABC;
			isregalu = 1;
			isvalid = 1;
			regwrite = 1;
			aluop = `ALU_AND;
			
			//isregalu = 0;
			isimmalu = 0;
			//isvalid = 0;
			issystem = 0;
			//regwrite = 0;
			//aluop = 0;
			valsize = 0;
			ctrlread = 0;
			ctrlwrite = 0;
			dataread = 0;
			datawrite = 0;
			extnread = 0;
			extnwrite = 0;
			getpc = 0;
			setpc = 0;
			blink = 0;
			bto = 0;
			bif = 0;
			//encoding = 0;
			bswitch = 0;
		end
		`OP_OR: begin
			encoding = `ENCODING_OPABC;
			isregalu = 1;
			isvalid = 1;
			regwrite = 1;
			aluop = `ALU_OR;
			
			//isregalu = 0;
			isimmalu = 0;
			//isvalid = 0;
			issystem = 0;
			//regwrite = 0;
			//aluop = 0;
			valsize = 0;
			ctrlread = 0;
			ctrlwrite = 0;
			dataread = 0;
			datawrite = 0;
			extnread = 0;
			extnwrite = 0;
			getpc = 0;
			setpc = 0;
			blink = 0;
			bto = 0;
			bif = 0;
			//encoding = 0;
			bswitch = 0;
		end
		`OP_XOR: begin
			encoding = `ENCODING_OPABC;
			isregalu = 1;
			isvalid = 1;
			regwrite = 1;
			aluop = `ALU_XOR;
			
			//isregalu = 0;
			isimmalu = 0;
			//isvalid = 0;
			issystem = 0;
			//regwrite = 0;
			//aluop = 0;
			valsize = 0;
			ctrlread = 0;
			ctrlwrite = 0;
			dataread = 0;
			datawrite = 0;
			extnread = 0;
			extnwrite = 0;
			getpc = 0;
			setpc = 0;
			blink = 0;
			bto = 0;
			bif = 0;
			//encoding = 0;
			bswitch = 0;
		end
		`OP_SHL: begin
			encoding = `ENCODING_OPABC;
			isregalu = 1;
			isvalid = 1;
			regwrite = 1;
			aluop = `ALU_SHL;
			
			//isregalu = 0;
			isimmalu = 0;
			//isvalid = 0;
			issystem = 0;
			//regwrite = 0;
			//aluop = 0;
			valsize = 0;
			ctrlread = 0;
			ctrlwrite = 0;
			dataread = 0;
			datawrite = 0;
			extnread = 0;
			extnwrite = 0;
			getpc = 0;
			setpc = 0;
			blink = 0;
			bto = 0;
			bif = 0;
			//encoding = 0;
			bswitch = 0;
		end
		`OP_SHRZ: begin
			encoding = `ENCODING_OPABC;
			isregalu = 1;
			isvalid = 1;
			regwrite = 1;
			aluop = `ALU_SHRZ;
			
			//isregalu = 0;
			isimmalu = 0;
			//isvalid = 0;
			issystem = 0;
			//regwrite = 0;
			//aluop = 0;
			valsize = 0;
			ctrlread = 0;
			ctrlwrite = 0;
			dataread = 0;
			datawrite = 0;
			extnread = 0;
			extnwrite = 0;
			getpc = 0;
			setpc = 0;
			blink = 0;
			bto = 0;
			bif = 0;
			//encoding = 0;
			bswitch = 0;
		end
		`OP_SHRS: begin
			encoding = `ENCODING_OPABC;
			isregalu = 1;
			isvalid = 1;
			regwrite = 1;
			aluop = `ALU_SHRS;
			
			//isregalu = 0;
			isimmalu = 0;
			//isvalid = 0;
			issystem = 0;
			//regwrite = 0;
			//aluop = 0;
			valsize = 0;
			ctrlread = 0;
			ctrlwrite = 0;
			dataread = 0;
			datawrite = 0;
			extnread = 0;
			extnwrite = 0;
			getpc = 0;
			setpc = 0;
			blink = 0;
			bto = 0;
			bif = 0;
			//encoding = 0;
			bswitch = 0;
		end
		`OP_BLINK: begin
			encoding = `ENCODING_OPABC;
			isvalid = 1;
			blink = 1;
			regwrite = 1;
			
			isregalu = 0;
			isimmalu = 0;
			//isvalid = 0;
			issystem = 0;
			//regwrite = 0;
			aluop = 0;
			valsize = 0;
			ctrlread = 0;
			ctrlwrite = 0;
			dataread = 0;
			datawrite = 0;
			extnread = 0;
			extnwrite = 0;
			getpc = 0;
			setpc = 0;
			//blink = 0;
			bto = 0;
			bif = 0;
			//encoding = 0;
			bswitch = 0;
		end
		`OP_BTO: begin
			encoding = `ENCODING_OPABC; // Note, destination register is ignored in a plain bto
			isvalid = 1;
			bto = 1;
			
			isregalu = 0;
			isimmalu = 0;
			//isvalid = 0;
			issystem = 0;
			regwrite = 0;
			aluop = 0;
			valsize = 0;
			ctrlread = 0;
			ctrlwrite = 0;
			dataread = 0;
			datawrite = 0;
			extnread = 0;
			extnwrite = 0;
			getpc = 0;
			setpc = 0;
			blink = 0;
			//bto = 0;
			bif = 0;
			//encoding = 0;
			bswitch = 0;
		end
		`OP_BE: begin
			encoding = `ENCODING_OPABC;
			isvalid = 1;
			blink = 1;
			regwrite = 1;
			bto = 1;
			
			isregalu = 0;
			isimmalu = 0;
			//isvalid = 0;
			issystem = 0;
			//regwrite = 0;
			aluop = 0;
			valsize = 0;
			ctrlread = 0;
			ctrlwrite = 0;
			dataread = 0;
			datawrite = 0;
			extnread = 0;
			extnwrite = 0;
			getpc = 0;
			setpc = 0;
			//blink = 0;
			//bto = 0;
			bif = 0;
			//encoding = 0;
			bswitch = 0;
		end
		`OP_BEFORE: begin
			encoding = `ENCODING_OPABC; // Note, destination register is ignored in a plain before
			isvalid = 1;
			issystem = 1;
			bswitch = 1;
			
			isregalu = 0;
			isimmalu = 0;
			//isvalid = 0;
			//issystem = 0;
			regwrite = 0;
			aluop = 0;
			valsize = 0;
			ctrlread = 0;
			ctrlwrite = 0;
			dataread = 0;
			datawrite = 0;
			extnread = 0;
			extnwrite = 0;
			getpc = 0;
			setpc = 0;
			blink = 0;
			bto = 0;
			bif = 0;
			//encoding = 0;
			//bswitch = 0;
		end
		/*
		`OP_BRIF: begin
			isvalid = 1;
			getpc = 1;
			setpc = 1;
			breg = 1;
			bif = 1;
		end*/
		`OP_CTRLIN64: begin
			encoding = `ENCODING_OPABI;
			isvalid = 1;
			issystem = 1;
			ctrlread = 1;
			valsize = 3;
			regwrite = 1;
			
			isregalu = 0;
			isimmalu = 0;
			//isvalid = 0;
			//issystem = 0;
			//regwrite = 0;
			aluop = 0;
			//valsize = 0;
			//ctrlread = 0;
			ctrlwrite = 0;
			dataread = 0;
			datawrite = 0;
			extnread = 0;
			extnwrite = 0;
			getpc = 0;
			setpc = 0;
			blink = 0;
			bto = 0;
			bif = 0;
			//encoding = 0;
			bswitch = 0;
		end
		`OP_CTRLOUT64: begin
			encoding = `ENCODING_OPBCI;
			isvalid = 1;
			issystem = 1;
			ctrlwrite = 1;
			valsize = 3;
			
			isregalu = 0;
			isimmalu = 0;
			//isvalid = 0;
			//issystem = 0;
			regwrite = 0;
			aluop = 0;
			//valsize = 0;
			ctrlread = 0;
			//ctrlwrite = 0;
			dataread = 0;
			datawrite = 0;
			extnread = 0;
			extnwrite = 0;
			getpc = 0;
			setpc = 0;
			blink = 0;
			bto = 0;
			bif = 0;
			//encoding = 0;
			bswitch = 0;
		end
		`OP_READ32: begin
			encoding = `ENCODING_OPABI;
			isvalid = 1;
			dataread = 1;
			valsize = 2;
			regwrite = 1;
			
			isregalu = 0;
			isimmalu = 0;
			//isvalid = 0;
			issystem = 0;
			//regwrite = 0;
			aluop = 0;
			//valsize = 0;
			ctrlread = 0;
			ctrlwrite = 0;
			//dataread = 0;
			datawrite = 0;
			extnread = 0;
			extnwrite = 0;
			getpc = 0;
			setpc = 0;
			blink = 0;
			bto = 0;
			bif = 0;
			//encoding = 0;
			bswitch = 0;
		end
		`OP_WRITE32: begin
			encoding = `ENCODING_OPBCI;
			isvalid = 1;
			datawrite = 1;
			valsize = 2;
			
			isregalu = 0;
			isimmalu = 0;
			//isvalid = 0;
			issystem = 0;
			regwrite = 0;
			aluop = 0;
			//valsize = 0;
			ctrlread = 0;
			ctrlwrite = 0;
			dataread = 0;
			//datawrite = 0;
			extnread = 0;
			extnwrite = 0;
			getpc = 0;
			setpc = 0;
			blink = 0;
			bto = 0;
			bif = 0;
			//encoding = 0;
			bswitch = 0;
		end
		`OP_IN32: begin
			encoding = `ENCODING_OPABI;
			isvalid = 1;
			issystem = 1;
			extnread = 1;
			valsize = 2;
			regwrite = 1;
			
			isregalu = 0;
			isimmalu = 0;
			//isvalid = 0;
			//issystem = 0;
			//regwrite = 0;
			aluop = 0;
			//valsize = 0;
			ctrlread = 0;
			ctrlwrite = 0;
			dataread = 0;
			datawrite = 0;
			//extnread = 0;
			extnwrite = 0;
			getpc = 0;
			setpc = 0;
			blink = 0;
			bto = 0;
			bif = 0;
			//encoding = 0;
			bswitch = 0;
		end
		`OP_OUT32: begin
			encoding = `ENCODING_OPBCI;
			isvalid = 1;
			issystem = 1;
			extnwrite = 1;
			valsize = 2;
			
			isregalu = 0;
			isimmalu = 0;
			//isvalid = 0;
			//issystem = 0;
			regwrite = 0;
			aluop = 0;
			//valsize = 0;
			ctrlread = 0;
			ctrlwrite = 0;
			dataread = 0;
			datawrite = 0;
			extnread = 0;
			//extnwrite = 0;
			getpc = 0;
			setpc = 0;
			blink = 0;
			bto = 0;
			bif = 0;
			//encoding = 0;
			bswitch = 0;
		end
		`OP_IFABOVE: begin
			encoding = `ENCODING_OPBCI;
			isvalid = 1;
			isregalu = 1;
			bif = 1;
			aluop = 4'hA;
			
			//isregalu = 0;
			isimmalu = 0;
			//isvalid = 0;
			issystem = 0;
			regwrite = 0;
			//aluop = 0;
			valsize = 0;
			ctrlread = 0;
			ctrlwrite = 0;
			dataread = 0;
			datawrite = 0;
			extnread = 0;
			extnwrite = 0;
			getpc = 0;
			setpc = 0;
			blink = 0;
			bto = 0;
			//bif = 0;
			//encoding = 0;
			bswitch = 0;
		end
		`OP_IFBELOWS: begin
			encoding = `ENCODING_OPBCI;
			isvalid = 1;
			isregalu = 1;
			bif = 1;
			aluop = 4'hB;
			
			//isregalu = 0;
			isimmalu = 0;
			//isvalid = 0;
			issystem = 0;
			regwrite = 0;
			//aluop = 0;
			valsize = 0;
			ctrlread = 0;
			ctrlwrite = 0;
			dataread = 0;
			datawrite = 0;
			extnread = 0;
			extnwrite = 0;
			getpc = 0;
			setpc = 0;
			blink = 0;
			bto = 0;
			//bif = 0;
			//encoding = 0;
			bswitch = 0;
		end
		`OP_IFEQUALS: begin
			encoding = `ENCODING_OPBCI;
			isvalid = 1;
			isregalu = 1;
			bif = 1;
			aluop = 4'hE;
			
			//isregalu = 0;
			isimmalu = 0;
			//isvalid = 0;
			issystem = 0;
			regwrite = 0;
			//aluop = 0;
			valsize = 0;
			ctrlread = 0;
			ctrlwrite = 0;
			dataread = 0;
			datawrite = 0;
			extnread = 0;
			extnwrite = 0;
			getpc = 0;
			setpc = 0;
			blink = 0;
			bto = 0;
			//bif = 0;
			//encoding = 0;
			bswitch = 0;
		end
		default: begin
			isregalu = 0;
			isimmalu = 0;
			isvalid = 0;
			issystem = 0;
			regwrite = 0;
			aluop = 0;
			valsize = 0;
			ctrlread = 0;
			ctrlwrite = 0;
			dataread = 0;
			datawrite = 0;
			extnread = 0;
			extnwrite = 0;
			getpc = 0;
			setpc = 0;
			blink = 0;
			bto = 0;
			bif = 0;
			encoding = 0;
			bswitch = 0;
		end
	endcase
end

endmodule

module SimpleRegisters(reset, regA, regB, regC, write, inA, outB, outC, regvalid);
input reset;
input [7:0] regA;
input [7:0] regB;
input [7:0] regC;
input write;
input [63:0] inA;
output [63:0] outB;
output [63:0] outC;
output regvalid;

reg [63:0]regs[7:0];

always @(posedge write) begin
	if (reset) begin
		regs[0] = 0;
		regs[1] = 0;
		regs[2] = 0;
		regs[3] = 0;
		regs[4] = 0;
		regs[5] = 0;
		regs[6] = 0;
		regs[7] = 0;
		/*regs[8] = 0;
		regs[9] = 0;
		regs[10] = 0;
		regs[11] = 0;
		regs[12] = 0;
		regs[13] = 0;
		regs[14] = 0;
		regs[15] = 0;*/
		/*
		regs[16] = 0;
		regs[17] = 0;
		regs[18] = 0;
		regs[19] = 0;
		regs[20] = 0;
		regs[21] = 0;
		regs[22] = 0;
		regs[23] = 0;
		regs[24] = 0;
		regs[25] = 0;
		regs[26] = 0;
		regs[27] = 0;
		regs[28] = 0;
		regs[29] = 0;
		regs[30] = 0;
		regs[31] = 0;
		regs[32] = 0;
		regs[33] = 0;
		regs[34] = 0;
		regs[35] = 0;
		regs[36] = 0;
		regs[37] = 0;
		regs[38] = 0;
		regs[39] = 0;
		regs[40] = 0;
		regs[41] = 0;
		regs[42] = 0;
		regs[43] = 0;
		regs[44] = 0;
		regs[45] = 0;
		regs[46] = 0;
		regs[47] = 0;
		regs[48] = 0;
		regs[49] = 0;
		regs[50] = 0;
		regs[51] = 0;
		regs[52] = 0;
		regs[53] = 0;
		regs[54] = 0;
		regs[55] = 0;
		regs[56] = 0;
		regs[57] = 0;
		regs[58] = 0;
		regs[59] = 0;
		regs[60] = 0;
		regs[61] = 0;
		regs[62] = 0;
		regs[63] = 0;
		regs[64] = 0;
		regs[65] = 0;
		regs[66] = 0;
		regs[67] = 0;
		regs[68] = 0;
		regs[69] = 0;
		regs[70] = 0;
		regs[71] = 0;
		regs[72] = 0;
		regs[73] = 0;
		regs[74] = 0;
		regs[75] = 0;
		regs[76] = 0;
		regs[77] = 0;
		regs[78] = 0;
		regs[79] = 0;
		regs[80] = 0;
		regs[81] = 0;
		regs[82] = 0;
		regs[83] = 0;
		regs[84] = 0;
		regs[85] = 0;
		regs[86] = 0;
		regs[87] = 0;
		regs[88] = 0;
		regs[89] = 0;
		regs[90] = 0;
		regs[91] = 0;
		regs[92] = 0;
		regs[93] = 0;
		regs[94] = 0;
		regs[95] = 0;
		regs[96] = 0;
		regs[97] = 0;
		regs[98] = 0;
		regs[99] = 0;
		regs[100] = 0;
		regs[101] = 0;
		regs[102] = 0;
		regs[103] = 0;
		regs[104] = 0;
		regs[105] = 0;
		regs[106] = 0;
		regs[107] = 0;
		regs[108] = 0;
		regs[109] = 0;
		regs[110] = 0;
		regs[111] = 0;
		regs[112] = 0;
		regs[113] = 0;
		regs[114] = 0;
		regs[115] = 0;
		regs[116] = 0;
		regs[117] = 0;
		regs[118] = 0;
		regs[119] = 0;
		regs[120] = 0;
		regs[121] = 0;
		regs[122] = 0;
		regs[123] = 0;
		regs[124] = 0;
		regs[125] = 0;
		regs[126] = 0;
		regs[127] = 0;
		regs[128] = 0;
		regs[129] = 0;
		regs[130] = 0;
		regs[131] = 0;
		regs[132] = 0;
		regs[133] = 0;
		regs[134] = 0;
		regs[135] = 0;
		regs[136] = 0;
		regs[137] = 0;
		regs[138] = 0;
		regs[139] = 0;
		regs[140] = 0;
		regs[141] = 0;
		regs[142] = 0;
		regs[143] = 0;
		regs[144] = 0;
		regs[145] = 0;
		regs[146] = 0;
		regs[147] = 0;
		regs[148] = 0;
		regs[149] = 0;
		regs[150] = 0;
		regs[151] = 0;
		regs[152] = 0;
		regs[153] = 0;
		regs[154] = 0;
		regs[155] = 0;
		regs[156] = 0;
		regs[157] = 0;
		regs[158] = 0;
		regs[159] = 0;
		regs[160] = 0;
		regs[161] = 0;
		regs[162] = 0;
		regs[163] = 0;
		regs[164] = 0;
		regs[165] = 0;
		regs[166] = 0;
		regs[167] = 0;
		regs[168] = 0;
		regs[169] = 0;
		regs[170] = 0;
		regs[171] = 0;
		regs[172] = 0;
		regs[173] = 0;
		regs[174] = 0;
		regs[175] = 0;
		regs[176] = 0;
		regs[177] = 0;
		regs[178] = 0;
		regs[179] = 0;
		regs[180] = 0;
		regs[181] = 0;
		regs[182] = 0;
		regs[183] = 0;
		regs[184] = 0;
		regs[185] = 0;
		regs[186] = 0;
		regs[187] = 0;
		regs[188] = 0;
		regs[189] = 0;
		regs[190] = 0;
		regs[191] = 0;
		regs[192] = 0;
		regs[193] = 0;
		regs[194] = 0;
		regs[195] = 0;
		regs[196] = 0;
		regs[197] = 0;
		regs[198] = 0;
		regs[199] = 0;
		regs[200] = 0;
		regs[201] = 0;
		regs[202] = 0;
		regs[203] = 0;
		regs[204] = 0;
		regs[205] = 0;
		regs[206] = 0;
		regs[207] = 0;
		regs[208] = 0;
		regs[209] = 0;
		regs[210] = 0;
		regs[211] = 0;
		regs[212] = 0;
		regs[213] = 0;
		regs[214] = 0;
		regs[215] = 0;
		regs[216] = 0;
		regs[217] = 0;
		regs[218] = 0;
		regs[219] = 0;
		regs[220] = 0;
		regs[221] = 0;
		regs[222] = 0;
		regs[223] = 0;
		regs[224] = 0;
		regs[225] = 0;
		regs[226] = 0;
		regs[227] = 0;
		regs[228] = 0;
		regs[229] = 0;
		regs[230] = 0;
		regs[231] = 0;
		regs[232] = 0;
		regs[233] = 0;
		regs[234] = 0;
		regs[235] = 0;
		regs[236] = 0;
		regs[237] = 0;
		regs[238] = 0;
		regs[239] = 0;
		regs[240] = 0;
		regs[241] = 0;
		regs[242] = 0;
		regs[243] = 0;
		regs[244] = 0;
		regs[245] = 0;
		regs[246] = 0;
		regs[247] = 0;
		regs[248] = 0;
		regs[249] = 0;
		regs[250] = 0;
		regs[251] = 0;
		regs[252] = 0;
		regs[253] = 0;
		regs[254] = 0;
		regs[255] = 0;*/
	end else if (regvalid) begin
		regs[regA[2:0]] = inA;
	end
end

assign outB = regs[regB[2:0]];
assign outC = regs[regC[2:0]];
assign regvalid = ((regA[7:3] == 0) && (regB[7:3] == 0) && (regC[7:3] == 0)) ? 1 : 0;

endmodule

module SimpleALU(op, outA, inB, inC, aluvalid);
input [3:0]op;
output reg [63:0]outA;
input [63:0]inB;
input [63:0]inC;
output reg aluvalid;

always @(op) begin
	case (op)
		`ALU_NOP: begin
			outA = 0;
			aluvalid = 1;
		end
		`ALU_ADD: begin
			outA = inB + inC;
			aluvalid = 1;
		end
		`ALU_SUB: begin
			outA = inB - inC;
			aluvalid = 1;
		end
		`ALU_AND: begin
			outA = inB & inC;
			aluvalid = 1;
		end
		`ALU_OR: begin
			outA = inB | inC;
			aluvalid = 1;
		end
		`ALU_XOR: begin
			outA = inB ^ inC;
			aluvalid = 1;
		end
		`ALU_SHL: begin
			outA = inB << inC;
			aluvalid = 1;
		end
		`ALU_SHRZ: begin
			outA = inB >> inC;
			aluvalid = 1;
		end
		`ALU_SHRS: begin
			outA = inB >>> inC;
			aluvalid = 1;
		end
		`ALU_ABOVE: begin
			outA = (inB > inC) ? 1 : 0;
			aluvalid = 1;
		end
		`ALU_EQUALS: begin
			outA = (inB == inC) ? 1 : 0;
			aluvalid = 1;
		end
		default: begin
			outA = 0;
			aluvalid = 0;
		end
	endcase
end

endmodule
/* The SimpleTimer module is intended to implement a very basic timer interrupt source and counter for
 * multitasking and similar applications (e.g. animation or motor control). This timer is based on the
 * clock rate, which means it will always be fast enough to implement such features but the speed won't
 * be 1) the same on all different devices/configurations/modes or 2) reliable enough to use for
 * monitoring "wall time" (you'll probably want a separate battery-backed clock for that anyway).
 *
 * Typically, an operating system would use this kind of timer for e.g. millisecond-level precision but
 * would first check the number of timer clocks against a second or so of wall time from an external clock
 * in order to synchronise the numbers. It would then either maintain an internal representation of wall time
 * that it updates regularly based on the simple timer (and other info such as locale) and occasionally e.g.
 * each minute synchronises this with the value from the external clock, or it would simply rely on the external
 * clock directly for checking wall time.
 *
 * For cases where wall time isn't directly important, the timer rate still matters for efficiency (e.g. setting it too
 * high would waste time doing too many timer interrupts or too low wouldn't run the timer interrupt often enough
 * to use it to track anything useful). Devices like serial connections (at least if they're driven directly by the CPU)
 * typically also need to be driven at certain rates (or at least within certain timing parameters).
 */
module SimpleTimer(clock,reset,ctrlin,ctrlout);
input clock;
input reset;
input [63:0]ctrlin;
output [63:0]ctrlout;

reg dingdong;

wire ctrlin_clear				= ctrlin[0];
wire ctrlin_enablealarm		= ctrlin[1];
wire ctrlin_enableforget	= ctrlin[2];
wire ctrlin_sleep				= ctrlin[3];
wire [4:0]ctrlin_alarmshift = ctrlin[12:8];
wire [4:0]ctrlin_forgetshift = ctrlin[20:16];

wire [63:0]alarmval = (64'h10 << ctrlin_alarmshift);
wire [63:0]forgetval = (64'h10 << ctrlin_forgetshift);

reg [63:0] count;
reg [63:0] ncount;

assign ctrlout = (count & 64'hFFFFFFFFFFFFFF00) | dingdong;

always @(posedge clock) begin
	if (reset || ctrlin_clear) begin
		count = 0;
	end else begin
		count = ncount;
	end
end

always @(negedge clock) begin
	if (reset || ctrlin_clear) begin
		ncount = 0;
		dingdong = 0;
	end else begin
		if (ctrlin_sleep) begin
			dingdong = 0;
		end else if (ctrlin_enablealarm && (count == alarmval)) begin
			dingdong = 1;
		end
		
		if (ctrlin_enableforget && (count == forgetval)) begin
			ncount = 0;
		end else begin
			ncount = count + 1;
		end
	end
end

endmodule

module SimpleCore(clock,reset,address,dsize,din,dout,readins,readmem,readio,writemem,writeio,ready,sysmode,dblflt,busx,hwx,hwxa,stage);
input clock;
input reset;
output reg [63:0] address;
output reg [1:0] dsize;
input [63:0] din;
output reg [63:0] dout;
output reg readins;
output reg readmem;
output reg readio;
output reg writemem;
output reg writeio;
input ready;
output sysmode;
output reg dblflt;
input busx;
input hwx;
output reg hwxa;

output reg [5:0] stage = 0;

reg [5:0] nstage = 0;

reg [63:0] pc = 0;
reg [63:0] npc = 0;
reg [63:0] flags = `FLAGS_INITIAL;
reg [63:0] nflags = `FLAGS_INITIAL;
reg [63:0] mirrorflags = `MIRRORFLAGS_INITIAL;
reg [63:0] nmirrorflags = `MIRRORFLAGS_INITIAL;
reg [63:0] xaddr = 0;
reg [63:0] nxaddr = 0;
reg [63:0] mirrorxaddr = 0;
reg [63:0] nmirrorxaddr = 0;
reg [1:0] inssize = 2'b10;
reg [31:0] ins = 0;

assign sysmode = flags[0:0];
wire excnenable = flags[1:1];
wire tmxenable = flags[2:2];
wire hwxenable = flags[3:3];

wire isregalu;
wire isimmalu;
wire isvalid;
wire issystem;
wire [7:0]aluop;
wire [63:0]imm;
wire [7:0]regA;
wire [7:0]regB;
wire [7:0]regC;
wire regwrite;
wire [1:0]valsize;
wire ctrlread;
wire ctrlwrite;
wire dataread;
wire datawrite;
wire extnread;
wire extnwrite;
wire getpc;
wire setpc;
wire blink;
wire bto;
wire bswitch;
wire bif;
wire needsbus = dataread || datawrite || extnread || extnwrite;
//reg decodeclk = 0;
// (ins, isregalu, isimmalu, isvalid, issystem, regA, regB, regC, regwrite, aluop, imm, valsize, ctrlread, ctrlwrite, dataread, datawrite, extnread, extnwrite, getpc, setpc, blink, bto, bswitch, bif)
SimpleDecoder decoder(/*decodeclk, */ins, isregalu, isimmalu, isvalid, issystem, regA, regB, regC, regwrite, aluop, imm, valsize, ctrlread, ctrlwrite, dataread, datawrite, extnread, extnwrite, getpc, setpc, blink, bto, bswitch, bif);

reg [63:0]regInA;
wire [63:0]regOutB;
wire [63:0]regOutC;
wire regvalid;
reg reallyregwrite = 0;

SimpleRegisters registers(reset, regA, regB, regC, reallyregwrite || reset, regInA, regOutB, regOutC, regvalid);

wire [63:0]aluOutA;
wire [63:0]aluInB = regOutB;
wire [63:0]aluInC = isregalu ? regOutC : imm;
wire aluvalid;

SimpleALU alu(aluop, aluOutA, aluInB, aluInC, aluvalid);

reg [63:0] timerctrlin;
wire [63:0] timerctrlout;
wire timerinterrupt = timerctrlout[0];
SimpleTimer timer(clock, reset, timerctrlin, timerctrlout);

reg [3:0] excn;

always @(posedge clock) begin
	if (reset) begin
		stage = 0;
	end else begin
		stage = nstage;
	end
end

reg [3:0]ctrln;

wire [63:0]ctrlv = (ctrln == `CTRL_FLAGS) ? flags : ((ctrln == `CTRL_MIRRORFLAGS) ? mirrorflags
	: ((ctrln == `CTRL_XADDR) ? xaddr : ((ctrln == `CTRL_MIRRORXADDR) ? mirrorxaddr
	: ((ctrln == `CTRL_EXCN) ? excn : ((ctrln == `CTRL_TIMER) ? timerctrlout : 0)))));

always @(negedge clock) begin
	if (reset) begin
		address = 0;
		dsize = 0;
		dout = 0;
		readins = 0;
		readmem = 0;
		readio = 0;
		writemem = 0;
		writeio = 0;
		//sysmode = 0;
		dblflt = 0;
		hwxa = 0;
		nstage = 0;
		excn = 0;
		ctrln = 0;
		
		pc = 0;
		npc = 0;
		flags = `FLAGS_INITIAL;
		nflags = `FLAGS_INITIAL;
		mirrorflags = `MIRRORFLAGS_INITIAL;
		nmirrorflags = `MIRRORFLAGS_INITIAL;
		xaddr = 0;
		nxaddr = 0;
		mirrorxaddr = 0;
		nmirrorxaddr = 0;
		
		timerctrlin = 0;
	end else begin
		case (stage)
			/* The INITIAL stage either happens after the end of the previous instruction, or directly after a reset.
		    * It sets the program counter and address/readins lines but clears most other temporary or output values to a
			 * default zero state.
			 */
			`STAGE_INITIAL: begin
				ins = 0;
				address = npc;
				pc = npc;
				flags = nflags;
				mirrorflags = nmirrorflags;
				xaddr = nxaddr;
				mirrorxaddr = nmirrorxaddr;
				dsize = inssize;
				readins = 1;
				nstage = `STAGE_FETCH;
				ctrln = 0;
			end
			/* The FETCH stage repeats until either the instruction (from the memory bus) is ready or until an
		    * bus/timer/hardware exception is generated, and will then proceed to either decode the instruction or
			 * to process the exception. If the instruction is ready to be processed, this stage will set the internal
			 * instruction register to that value and increment the next-PC value (which might be reassigned in a later
			 * stage anyway e.g. for a jump or if another exception is generated - but would otherwise just point to "the
			 * next instruction").
			 */
			`STAGE_FETCH: begin
				if (busx) begin
					excn = `EXCN_BADDOG;
					nstage = `STAGE_EXCEPTION;
				end else if (tmxenable && timerinterrupt) begin
					excn = `EXCN_DINGDONG;
					nstage = `STAGE_EXCEPTION;
				end else if (hwxenable && hwx) begin
					excn = `EXCN_HARDWARE;
					nstage = `STAGE_EXCEPTION;
				end else if (ready) begin
					ins[31:0] = din[31:0];
					nstage = `STAGE_DECODE;//HACK; // See note below
					//decodeclk = 0;
					npc = pc + 4;	// Note, a branch/if instruction will alter npc in a later stage if necessary
										// But also note, it may perform separate calculation of the pc + 4 address
				end else begin
					nstage = `STAGE_FETCH;
				end
			end
			/* There were some issues making the decoder more-continuous, so for now there's a clock signal to decode. */
			/*`STAGE_DECODEHACK: begin
				decodeclk = 1;
				nstage = `STAGE_DECODE;
			end*/
			/* The DECODE stage tests for most other exceptions and otherwise does any final register or ALU setup
		    * that would be necessary before retrieving or saving a result later. This stage is also responsible
			 * for deciding whether to proceed to the bus read/write stages or directly to the SAVE/CLEANUP stages.
			 */
			`STAGE_DECODE: begin
				//decodeclk = 0;
				address = 0;
				dsize = 0;
				readins = 0;
				if (!isvalid) begin
					excn = `EXCN_INVALIDINSTR;
					nstage = `STAGE_EXCEPTION;
				end else if (issystem && !sysmode) begin
					excn = `EXCN_SYSMODEINSTR;
					nstage = `STAGE_EXCEPTION;
				end else if (!regvalid) begin
					excn = `EXCN_REGISTERERROR;
					nstage = `STAGE_EXCEPTION;
				end else if (!aluvalid) begin
					excn = `EXCN_ALUERROR;
					nstage = `STAGE_EXCEPTION;
				end else if (needsbus) begin
					nstage = `STAGE_SETBUS;
				end else begin
					regInA = blink ? pc + 4 : (ctrlread ? ctrlv : aluOutA);
					nstage = `STAGE_SAVE;
					if (ctrlread || ctrlwrite) begin
						ctrln = (regOutB + imm);
					end
				end
			end
			/* The SETBUS stage is responsible for setting up the memory/IO bus for a read or write operation, but
			 * the operation is not finalised until the next stage.
			 */
			`STAGE_SETBUS: begin
				address = regOutB + imm;
				dsize = valsize;
				readmem = dataread;
				writemem = datawrite;
				readio = extnread;
				writeio = extnwrite;
				dout = (datawrite || extnwrite) ? regOutC : 0;
				nstage = `STAGE_GETBUS;
			end
			/* The GETBUS stage is responsible for waiting for the ready signal or otherwise detecting any bus exceptions
			 * caused by a read/write operation. It also retrieves the data from the bus input (which is only important
			 * for a read operation). The bus is not cleared again until the next stage (in case clearing it would instantly
			 * destabilise the inputs, which may depend on the hardware).
			 */
			`STAGE_GETBUS: begin
				if (busx) begin
					excn = `EXCN_BUSERROR;
					nstage = `STAGE_EXCEPTION;
				end else if (ready) begin
					regInA = din;
					nstage = `STAGE_SAVE;
				end else begin
					nstage = `STAGE_GETBUS;
				end
			end
			/* The SAVE stage is essentially responsible for saving the value of the target register, but also performs
		    * some minor cleanup from previous stages (e.g. clearing the bus outputs so the memory doesn't read/write again)
			 * before proceeding to the final CLEANUP stage.
			 */
			`STAGE_SAVE: begin
				address = 0;
				dsize = 0;
				readins = 0;
				readmem = 0;
				writemem = 0;
				readio = 0;
				writeio = 0;
				if (regwrite) begin
					reallyregwrite = 1;
				end
				nstage = `STAGE_CLEANUP;
			end
			/* The CLEANUP stage is responsible for any final alterations to control registers before
		    * proceeding to the INITIAL stage to process the next instruction. It's main job is performing
			 * any final branch/jump operations or flag changes before they are applied for the next
			 * instruction (NOTE: Some or all of this can probably be moved into an earlier stage but for now
			 * makes more sense separately for design/debugging.)
			 */
			`STAGE_CLEANUP: begin
				reallyregwrite = 0;
				/* By default, next PC has already been set to PC + 4, but a branch will override
			    * that. The PC is then replaced by the next PC at the start of the next instruction
				 * (similar to flags and nflags etc.).
				 */
				if (bto) begin
					npc = regOutC;
					/* In normal operation, flags etc. stay the same. But they are swapped
					 * instead if there's an exception or similar mode-switch, so the new flags
					 * etc. are re-asserted here but only finally applied at the start of the
					 * next instruction.
					 */
					nflags = flags;
					nmirrorflags = mirrorflags;
					nxaddr = xaddr;
					nmirrorxaddr = mirrorxaddr;
				end else if (bif && (aluOutA != 0)) begin
					npc = {pc[63:18],imm[15:0],2'b00};
					/* In normal operation, flags etc. stay the same. But they are swapped
					 * instead if there's an exception or similar mode-switch, so the new flags
					 * etc. are re-asserted here but only finally applied at the start of the
					 * next instruction.
					 */
					nflags = flags;
					nmirrorflags = mirrorflags;
					nxaddr = xaddr;
					nmirrorxaddr = mirrorxaddr;
				end else if (bswitch) begin
					/* This is basically the inverse of what happens when an exception occurs (i.e. it returns
					 * from an exception). The main difference is that the program counter isn't saved, the old
					 * one is just returned. Note that this will repeat the original instruction. If you need to
					 * emulate the instruction instead (or perform the associated system call) you'll need to add
					 * 4 to mirrorxaddr manually.
					 */
					nflags = mirrorflags;
					nmirrorflags = flags;
					nxaddr = mirrorxaddr;
					nmirrorxaddr = xaddr;
					npc = mirrorxaddr;
				end else begin
					/* In normal operation, flags etc. stay the same. But they are swapped
					 * instead if there's an exception or similar mode-switch, so the new flags
					 * etc. are re-asserted here but only finally applied at the start of the
					 * next instruction.
					 *
					 * If they're changed by the user, the changes will be applied to the next values here
					 * and will take effect at the start of the next instruction.
					 */
					nflags = (ctrlwrite && (ctrln == `CTRL_FLAGS)) ? regOutC : flags;
					nmirrorflags = (ctrlwrite && (ctrln == `CTRL_MIRRORFLAGS)) ? regOutC : mirrorflags;
					nxaddr = (ctrlwrite && (ctrln == `CTRL_XADDR)) ? regOutC : xaddr;
					nmirrorxaddr = (ctrlwrite && (ctrln == `CTRL_MIRRORXADDR)) ? regOutC : mirrorxaddr;
					if (ctrlwrite && (ctrln == `CTRL_TIMER)) begin
						timerctrlin = regOutC;
					end
				end
				nstage = `STAGE_INITIAL;
			end
			/* The EXCEPTION stage begins exception-handling operations for both internal exceptions (e.g. invalid
		    * instruction) and external exceptions (i.e. hardware interrupts) as well as bus exceptions (which fit
			 * somewhere inbetween those). Exception-handling is the main reason I went with a many-stage design,
			 * since this allows things to be handled very precisely.
			 */
			`STAGE_EXCEPTION: begin
				/* The basic requirement of the exception stage is to switch modes (and jump to the exception handler
			    * software), however it must also handle cases where software exception-handling is not set up. This
				 * might sound unimportant (since you can just set up a software handler to catch them) however the
				 * handler generally needs to be disabled when catching exceptions to prevent recursion. So in these
				 * cases, we just set a "double fault" flag for now so this case is easy to detect on boards.
				 *
				 * This isn't so much of a problem with external interrupts (because handling them can be delayed)
				 * or with system calls (because they generally wouldn't call themselves recursively anyway), but
				 * more broadly will happen if there's an unexpected problem within the exception-handling or setup code
				 * (e.g. if the exception handler is at an invalid address, jumping there would trigger another exception,
				 * hence why interrupts should typically be disabled upon such a jump so such cases would trigger a
				 * detectable double-fault rather than producing undefined behaviour or an infinite loop).
				 */
				address = 0;
				dsize = 0;
				readins = 0;
				readmem = 0;
				writemem = 0;
				readio = 0;
				writeio = 0;
				if (excnenable) begin
					nflags = mirrorflags;
					nmirrorflags = flags;
					nxaddr = mirrorxaddr;
					nmirrorxaddr = pc;
					npc = xaddr;
					if ((excn == `EXCN_DINGDONG) || (excn == `EXCN_HARDWARE)) begin
						nstage = `STAGE_XACK;
					end else begin
						nstage = `STAGE_INITIAL;
					end
				end else begin
					dblflt = 1;
					nstage = `STAGE_EXCEPTION;
				end
			end
			/* The XACK stage happens after EXCEPTION if it was a hardware or timer exception, and will
		    * simply set the appropriate acknowledge signal and then go to STAGE_XWAIT.
			 */
			`STAGE_XACK: begin
				if (excn == `EXCN_DINGDONG) begin
					timerctrlin[3] = 1;
				end else begin // EXCN_HARDWARE
					hwxa = 1;
				end
				nstage = `STAGE_XWAIT;
			end
			/* The XWAIT stage happens after XACK, and basically just repeats until the previously-acknowledged
			 * interrupt request line goes low, at which point it will set the appropriate acknowledge line to
			 * low and proceed to the next instruction (which will be at the address of the interrupt handler
			 * which was set up in STAGE_EXCEPTION).
			 */
			`STAGE_XWAIT: begin
				if ((excn == `EXCN_DINGDONG) && (timerinterrupt == 0)) begin
					timerctrlin[3] = 0;
					nstage = `STAGE_INITIAL;
				end else if ((excn == `EXCN_HARDWARE) && (hwx == 0)) begin
					hwxa = 0;
					nstage = `STAGE_INITIAL;
				end else begin
					nstage = `STAGE_XWAIT;
				end
			end
			default: nstage = `STAGE_ERROR;
		endcase
	end
end

/* Just for the sake of debugging, this is the bits of the address that can easily be debugged over a few LEDs for
 * testing that loop-like code passes correctly.
 */
wire [3:0] effaddress = address[5:2];

initial
	//clock,reset,address,dsize,din,dout,readins,readmem,readio,writemem,writeio,ready,sysmode,dblflt,busx,hwx,hwxa,stage
		$monitor("%t: clock=xx reset=%b\naddress=%h (effective %d) dsize=%d din=%h dout=%h\nreadins=%b readmem=%b readio=%b writemem=%b writeio=%b\nready=%b sysmode=%b dblflt=%b busx=%b hwx=%b hwxa=%b\nstage=%d\nexcn=%d\ndecodeclk=%b ins=%h\nisvalid=%b issystem=%b\npc=%h npc=%h",
			$time, /*clock,*/ reset,
			address, effaddress, dsize, din, dout,
			readins, readmem, readio, writemem, writeio,
			ready, sysmode, dblflt, busx, hwx, hwxa,
			stage,
			excn,
			decodeclk, ins,
			isvalid, issystem,
			pc, npc);

endmodule