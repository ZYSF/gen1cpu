module SimpleMCU(
	input wire clk, // 50MHz input clock
	 //input wire reset, // unused
    output wire LED0, // LED ouput
	 output wire LED1,
	 output wire LED2,
	 output wire LED3
);

reg [31:0]ram[8191:0];

reg [31:0]count = 0;
reg reset = 1;

always @(posedge clk) begin
	if (count[25]) reset = 0;
end
always @(negedge clk) begin
	count = count + 1;
end

wire [63:0]address;
wire [1:0]dsize;
reg [63:0]din;
wire [63:0]dout;
wire readins;
wire readmem;
wire readio;
wire writemem;
wire writeio;
reg ready = 0;
wire sysmode;
wire dblflt;
reg busx = 0;
reg hwx = 0;
wire hwxa;
wire [5:0]stage;
reg [63:0] gpioain = 0;
wire [63:0] gpioaout;

always @(posedge clk) begin
	if ((readins || readmem || writemem) && ((address >= (8191 << 2)) || (address[1:0] != 0) || (dsize != 2))) begin
		busx = 1;
		ready = 0;
	end else if (readins || readmem) begin
		din = {32'h00000000,ram[address[14:2]]};
		busx = 0;
		ready = 1;
	end else if (writemem) begin
		ram[address[14:2]] = dout[31:0];
		busx = 0;
		ready = 1;
	end else begin
		ready = 0;
		busx = 0;
	end
end

//module SimpleCore(clock,reset,address,dsize,din,dout,readins,readmem,readio,writemem,writeio,ready,sysmode,dblflt,busx,hwx,hwxa,stage)
SimpleCore core(count[24], reset, address, dsize, din, dout, readins, readmem, readio, writemem, writeio, ready, sysmode, dblflt, busx, hwx, hwxa, gpioain, gpioaout, stage);

/*assign LED0 = !sysmode;
assign LED1 = !dblflt;
assign LED2 = !stage[1];
assign LED3 = !stage[0];*/
assign LED3 = !address[5];
assign LED2 = !address[4];
assign LED1 = !address[3];
assign LED0 = !address[2];

//assign din = {32'h00000000,ram[address[8:2]]};

initial begin
//	`define OP_SYSCALL		8'h00	// 0x00??????: invalid instruction, but reserved for encoding system calls
//	`define OP_ADDIMM			8'h11	// 0x11abiiii: a=b+i; // NOTE: Can only access lower 16 registers due to encoding
//	`define OP_ADD				8'hA1	// 0xA1aabbcc: a=b+c; // NOTE: Encoding allows up to 256 registers, but higher ones might be disabled
//	`define OP_SUB				8'hA2	// 0xA2aabbcc: a=b-c;
//	`define OP_AND				8'hA3
//	`define OP_OR				8'hA4
//	`define OP_XOR				8'hA5
//	`define OP_SHL				8'hA6
//	`define OP_SHRZ			8'hA7
//	`define OP_SHRS			8'hA8
//	`define OP_BLINK			8'hB1	// 0xB1aaxxxx: a = pc + 4;
//	`define OP_BTO				8'hB2	// 0xB2xxxxcc: npc = c;
//	`define OP_BE				8'hB3 // 0xB3aaxxcc: a = pc + 4; npc = c; // This is short for branch-and-enter
//	`define OP_BEFORE			8'hB4 // 0xB4xxxxxx: npc = before; nflags = mirrorflags; nmirrorflags = flags; nbefore = mirrorbefore; nmirrorbefore = before;
//	`define OP_BAIT			8'hB8 // 0xB8xxxxxx: invalid instruction, but reserved for traps.
//	`define OP_CTRLIN64		8'hC3	// 0xC3abiiii: a=ctrl[b+i];
//	`define OP_CTRLOUT64		8'hCB	// 0xCBbciiii: ctrl[b+i]=c;
//	`define OP_READ32			8'hD2 // 0xD2abiiii: a=data[b+i];
//	`define OP_WRITE32		8'hDA	// 0xDAbciiii: data[b+i]=c;
//	`define OP_IN32			8'hE2	// 0xE2abiiii: a=ext[b+i];
//	`define OP_OUT32			8'hEA	// 0xEAbciiii: ext[b+i]=c;
//	`define OP_IFABOVE		8'hFA	// 0xFAbciiii: if((unsigned) b > (unsigned) c){npc = pc + (i<<2);}
//	`define OP_IFBELOWS		8'hFB // 0xFBbciiii: if((signed) b < (signed) c){npc = pc + (i<<2);}
//	`define OP_IFEQUALS		8'hFE	// 0xFEbciiii: if(b == c){npc = pc + (i<<2);}
	ram[0] = 32'hFE000007; // Jump to address 16 (if R0 == R0)
	ram[1] = 0;
	ram[2] = 0;
	ram[3] = 0;
	ram[4] = 0;
	ram[5] = 0;
	ram[6] = 0;
	ram[7] = 32'hA5000000; // R0 = R0 XOR R0 (always resulting in 0)
	ram[8] = 32'h11000008; // R0 = R0 + 8
	ram[9] = 32'hDA000004; // Write R0 (8) to address R0+4 (12, or ram slot 3)
	ram[10] = 32'hFE00000A; // Infinite loop
	ram[11] = 0;
	ram[12] = 0;
	ram[13] = 0;
	ram[14] = 0;
	ram[15] = 0;
	ram[16] = 32'h11000008; // R0 = R0 + 8
	ram[17] = 32'hEA000004; // Write R0 (8) to address R0+4 (12, or ram slot 3)
	ram[18] = 32'hFE000000; // Jump back to start
	ram[19] = 0;
	ram[20] = 0;
	ram[21] = 0;
	ram[22] = 0;
	ram[23] = 0;
	ram[24] = 0;
	ram[25] = 0;
	ram[26] = 0;
	ram[27] = 0;
	ram[28] = 0;
	ram[29] = 0;
	ram[30] = 0;
	ram[31] = 0;
	ram[32] = 0;
	ram[33] = 0;
	ram[34] = 0;
	ram[35] = 0;
	ram[36] = 0;
	ram[37] = 0;
	ram[38] = 0;
	ram[39] = 0;
	ram[40] = 0;
	ram[41] = 0;
	ram[42] = 0;
	ram[43] = 0;
	ram[44] = 0;
	ram[45] = 0;
	ram[46] = 0;
	ram[47] = 0;
	ram[48] = 0;
	ram[49] = 0;
	ram[50] = 0;
	ram[51] = 0;
	ram[52] = 0;
	ram[53] = 0;
	ram[54] = 0;
	ram[55] = 0;
	ram[56] = 0;
	ram[57] = 0;
	ram[58] = 0;
	ram[59] = 0;
	ram[60] = 0;
	ram[61] = 0;
	ram[62] = 0;
	ram[63] = 0;
	ram[64] = 0;
	ram[65] = 0;
	ram[66] = 0;
	ram[67] = 0;
	ram[68] = 0;
	ram[69] = 0;
	ram[70] = 0;
	ram[71] = 0;
	ram[72] = 0;
	ram[73] = 0;
	ram[74] = 0;
	ram[75] = 0;
	ram[76] = 0;
	ram[77] = 0;
	ram[78] = 0;
	ram[79] = 0;
	ram[80] = 0;
	ram[81] = 0;
	ram[82] = 0;
	ram[83] = 0;
	ram[84] = 0;
	ram[85] = 0;
	ram[86] = 0;
	ram[87] = 0;
	ram[88] = 0;
	ram[89] = 0;
	ram[90] = 0;
	ram[91] = 0;
	ram[92] = 0;
	ram[93] = 0;
	ram[94] = 0;
	ram[95] = 0;
	ram[96] = 0;
	ram[97] = 0;
	ram[98] = 0;
	ram[99] = 0;
	ram[100] = 0;
	ram[101] = 0;
	ram[102] = 0;
	ram[103] = 0;
	ram[104] = 0;
	ram[105] = 0;
	ram[106] = 0;
	ram[107] = 0;
	ram[108] = 0;
	ram[109] = 0;
	ram[110] = 0;
	ram[111] = 0;
	ram[112] = 0;
	ram[113] = 0;
	ram[114] = 0;
	ram[115] = 0;
	ram[116] = 0;
	ram[117] = 0;
	ram[118] = 0;
	ram[119] = 0;
	ram[120] = 0;
	ram[121] = 0;
	ram[122] = 0;
	ram[123] = 0;
	ram[124] = 0;
	ram[125] = 0;
	ram[126] = 0;
	ram[127] = 0;
end

endmodule
