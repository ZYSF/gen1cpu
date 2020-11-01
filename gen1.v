`include "gen1defs.v"
module gen1(
	input clk, // The clock (most logic happens at/after the start of the high signal [while input signals may still be finalising], while most registers/effects are finalised at the end of the high signal)
	input reset, // high to reset, low once (re-)activated
	input enable, // high if core should continue (i.e. the inverse of reset)
	`ifdef GEN1_INT64
	output [63:0]pcout, // instruction address to read
	`else
	output [31:0]pcout, // instruction address to read
	`endif
	input [31:0]instruction, // instruction input (read on posedge?)
	output m_read,
	output m_write,
	`ifdef GEN1_INT64
	output [63:0]m_addr,
	`else
	output [31:0]m_addr,
	`endif
	input [31:0]m_datain,
	output [31:0]m_dataout,
	input m_readturn,
	input m_writeturn,
	input [15:0] iixr, // Interface interrupt/exception request
	// NOTE: iixr is masked with internal interrupt flags to become eixr, effective interrupt/exception request
	output reg [15:0] ixa, // Interrupt/exception acknowledged
	output reg [3:0] ixt, // Interrupt/exception triggered (may help debug when internal interrupts occur)
	output [3:0]sysflags // These are bits 19:16 of cflags
	);
	`ifdef GEN1_INT64
	wire [63:0] GEN1_INSTRINCR;  // This didn't work as a define for some reason (I thought Verilog defines were like C?)
	`else
	wire [31:0] GEN1_INSTRINCR;  // This didn't work as a define for some reason (I thought Verilog defines were like C?)
	`endif
	`ifdef GEN1_WORDADDR
	assign GEN1_INSTRINCR = 1;
	`else
	assign GEN1_INSTRINCR = 4;
	`endif
	
	//output reg [31:0]m_addr; // alias
	//reg m_read;
	//reg m_write;
	 //wire [31:0]pcout;
	 `ifdef GEN1_INT64
	 wire [63:0]address;
	 wire [63:0]readdata1;
	 wire [63:0]readdata2;
	 wire [63:0]signextended;
	 wire [63:0]alumuxout;
	 wire [63:0]aluout;
	 wire [63:0]dataout;
	 wire [63:0]datamemout;
	 wire [63:0]datamuxout;
	 wire [63:0]outex;
	 wire [63:0]muxout;
	 wire [63:0]jout;
	 `else
	 wire [31:0]address;
	 wire [31:0]readdata1;
	 wire [31:0]readdata2;
	 wire [31:0]signextended;
	 wire [31:0]alumuxout;
	 wire [31:0]aluout;
	 wire [31:0]dataout;
	 wire [31:0]datamemout;
	 wire [31:0]datamuxout;
	 wire [31:0]outex;
	 wire [31:0]muxout;
	 wire [31:0]jout;
	 `endif
	 wire [4:0]regmuxout;
	 wire regwrite;
	 wire jump;
	 wire regdst;
	 wire branch;
	 wire zero;
	 wire [3:0]alucntrl;
	 wire alusrc;
	 wire linkpc;
	 wire jumpreg;
	 
	 `ifdef GEN1_INT64
	 reg [63:0] cflags; // Current flags
	 reg [63:0] mflags; // Mirror flags
	 reg [63:0] syslink; // Saved program counter from interrupt/exception
	 reg [63:0] next_cflags; // Current and mirror flags both have a next_ equivalent
	 reg [63:0] next_mflags; // This allows them to be swapped at syscall/sysret
	 reg [63:0] sysregA;	// The sysreg registers are accessible as coprocessor #0 registers 4 onwards
	 reg [63:0] sysregB;
	 reg [63:0] ixtable; // Pointer to the interrupt table
	 `else
	 reg [31:0] cflags; // Current flags
	 reg [31:0] mflags; // Mirror flags
	 reg [31:0] syslink; // Saved program counter from interrupt/exception
	 reg [31:0] next_cflags; // Current and mirror flags both have a next_ equivalent
	 reg [31:0] next_mflags; // This allows them to be swapped at syscall/sysret
	 reg [31:0] sysregA;	// The sysreg registers are accessible as coprocessor #0 registers 4 onwards
	 reg [31:0] sysregB;
	 reg [31:0] ixtable; // Pointer to the interrupt table
	 `endif
	 wire sysret;
	 wire swapflags;
	 wire cflags_sysmode;
	 assign cflags_sysmode = cflags[16:16]; // Lower 16 bits are the interrupt/exception enable bits, after which is sysmode
	 //assign cflags
	 //reg [31:0] next_ulink; // The ulink value is us
	 assign sysflags = cflags[19:16]; // The main purpose of this is exposing "are we in system mode" to the memory bus, but 3 extra flags are included for other/similar uses
	 
	 wire badinstr;
	wire [3:0] cixr; // Core interrupt/exceptions
	assign cixr[0:0] = ((cixr[3:1] & cflags[3:1]) == cixr[3:1]) ? 0 : 1; // ix#0 is double-fault, an internal exception has happened while handling disabled
	wire [15:0] eixr; // Effective interrupt/exception request
	wire [15:0] ixm; // Interrupt/exception mask
	wire ixnow; // Interrupt/exception NOW!
	reg ixhandling; // ixnow was high on negedge clk, which means this/next posedge (when PC gets updated) we are handling the interrupt/exception
	always @(negedge clk) begin
		ixhandling = reset ? 0 : ixnow;//(pcout == 8);//0;//ixnow;
	end
	reg [15:0] ixh; // Interrupt/exception being handled
	reg [3:0] ixn; // ixh number
	always @(reset) begin
		//ixhandling = 0;
		//ixh = 0;
		//ixn = 0;
		//cflags = 32'b11111111111111111;
		//mflags = 32'b01111111111111111;
		//next_cflags = 32'b11111111111111111;
		//next_mflags = 32'b01111111111111111;
		//sysregA = 0;
		//sysregB = 0;
		//syslink = 0;
		//ixa = 0;
		ixtable = 1024; // This should be configurable by code in the future, but for now the table is at 1KB
	end
	//assign cixr[0:0] = 0;
	assign cixr[1:1] = badinstr;
	assign cixr[3:2] = 0;
	assign eixr = iixr | cixr;
	assign ixm = eixr & (cflags[15:0] | 7); // Exception mask is set to ixr masked with cflags, but with the unmaskables kept unmasked
	assign ixnow = (ixm == 0) ? 0 : 1;	// If any interrupts/exceptions survive the masking, then we have an interrupt/exception NOW
	always @(negedge clk) begin
		ixt = cixr;
		if (eixr[0:0] != 0 && !reset) begin
			ixh=16'b00000001;
			ixa=16'b00000001;
			ixn=0;
		end else if (eixr[1:1] != 0 && !reset) begin
			ixh=16'b00000010;
			ixa=16'b00000010;
			ixn=1;
		end else if (eixr[2:2] != 0 && !reset) begin
			ixh=16'b00000100;
			ixa=16'b00000100;
			ixn=2;
		end else if (eixr[3:3] != 0 && !reset) begin
			ixh=16'b00001000;
			ixa=16'b00001000;
			ixn=3;
		end else if (ixnow && !reset) begin
			ixh=16'b00010000;
			ixa=16'b1111111111110000;
			ixn=4;
		end else begin
			ixh=0;
			ixn=0;
			ixa=0;
		end
	end
wire readsys;
wire writesys;
	 
// module control_mech(instruction,Rs,Func,RegDst,Jump,Branch,MemRead,MemtoReg,MemWrite,ALUSrc,RegWrite,ALUControl,LinkPC,JumpReg);
control_mech c(instruction[31:26],instruction[25:21],instruction[5:0],regdst,jump,branch,memread,memtoreg,memwrite,alusrc,regwrite,alucntrl,linkpc,jumpreg,swapflags,readsys,writesys,badinstr,sysmode,sysret);

// NOTE: This bit here is a little ugly, I couldn't work out how to get register/ALU-to-PC without basically performing the operation on
// the next cycle. So the jump-to-register instruction really just sets a flag for the next cycle. (One consequence is that it can't jump to
// another jump-to-register instruction.)
reg jumpregx;
reg pjumpregx;
`ifdef GEN1_INT64
reg [63:0]bypass;
`else
reg [31:0]bypass;
`endif
/*always @(reset) begin
jumpregx = 0;
pjumpregx = 0;
bypass=0;
end*/
always @(posedge clk) begin
pjumpregx = reset ? 0 : jumpregx;
end

always @(negedge clk) begin
bypass = reset ? 0 : sysret ? sysregA : aluout;
jumpregx = reset ? 0 : ((jumpreg || sysret) && !pjumpregx);
end
program_Counter pc(clk,reset,enable && (((!memread) && (!memwrite)) || ((memread && m_readturn) || (memwrite && m_writeturn))),jout,pcout,jumpregx,bypass,ixhandling,ixtable,ixn);
incrementor inc(pcout,clk,enable,address); // jumpreg overrides the incrementor so nextPC=aluout
//instruction_Memory im(pcout,instruction);
jumpandbranch bbb(instruction,address,outex,branch,zero,jump,jout);

alu bb(clk,readdata1,muxout,alucntrl,zero,aluout);
data_Mux dd(aluout,datamemout,memtoreg,datamuxout);

mux_Reg mm(regdst,instruction[20:16],instruction[15:11],regmuxout);
sign_Extender s(instruction[25:0],outex);
alu_Mux a(clk,readdata2,outex,alusrc,muxout);

`ifdef GEN1_INT64
wire [63:0]sysreadvalue;
`else
wire [31:0]sysreadvalue;
`endif
wire [3:0]sysregnum;
assign sysregnum = instruction[3:0]; // Just use lowest bits of instruction to select sysreg number for now.
assign sysreadvalue = (sysregnum == 0 ? cflags : (sysregnum == 1 ? mflags : (sysregnum == 2 ? syslink : (sysregnum == 4 ? sysregA : (sysregnum == 5 ? sysregB : 0)))));

// module register_File(ReadRegister1, ReadRegister2,WriteRegister,WriteData,RegWrite,Clk,Rst,ReadData1,ReadData2);
register_File regfile(instruction[25:21],instruction[20:16],(linkpc || sysread) ? 31 : regmuxout, linkpc ? address + GEN1_INSTRINCR : (sysread ? sysreadvalue : datamuxout),(regwrite || sysread) && !ixnow,clk,reset,readdata1,readdata2);
// module data_Memory(input Clk, input [31:0]address, input [31:0]writedata, input memread, input memwrite, output [31:0]readdata);
// data_Memory d(clk,aluout,readdata2,memread,memwrite,datamemout);
always @(posedge clk) begin
	next_cflags = reset ? 32'b11111111111111111 : cflags;
	next_mflags = reset ? 32'b01111111111111111 : mflags;
end
always @(negedge clk) begin
	if (ixnow && !reset) begin
		syslink = address - GEN1_INSTRINCR; // Hopefully, this is the address of the instruction which WASN'T finished when the interrupt/exception happened
	end else if (writesys && sysregnum == 2 && !reset) begin
		syslink = readdata2;
	end else if (writesys && sysregnum == 4 && !reset) begin
		sysregA = readdata2;
	end else if (writesys && sysregnum == 5 && !reset) begin
		sysregB = readdata2;
	end
	
	if (reset) begin
		mflags = 32'b01111111111111111;
		cflags = 32'b11111111111111111;
	end else if (swapflags || sysret || ixnow) begin
		mflags = next_cflags;
		cflags = next_mflags;
	end else begin
		cflags = (writesys && sysregnum == 0) ? readdata2 : next_cflags;
		mflags = (writesys && sysregnum == 1) ? readdata2 : next_mflags;
	end
end
/*always @(posedge clk) begin
	if(m_read || m_write) m_addr <= aluout;
	if(m_read || m_write) m_addr <= aluout;
 end*/
   //always @(jumpreg) begin
	//	address <= aluout;
	//end
	/*always @(negedge clk) begin // Note, we can afford to do this at negedge because we wait until ready.
		m_addr <= aluout;
		m_dataout <= (m_write) ? readdata2 : 0;
	end*/
	assign m_addr = (m_read || m_write) ? aluout : 0;
	assign m_dataout = (m_write) ? readdata2 : 0;
	//assign m_addr = aluout;
	//assign m_dataout = (m_write) ? readdata2 : 0;
	assign m_read = memread;
	assign m_write = memwrite;
	assign datamemout = (m_read) ? m_datain : 0;

initial
		$monitor("%t: clk=%b rst=%b enb=%b pcout=%d instr=%b regmuxout=%x rd1=%x rd2=%x aluout=%x\n\tm_read=%b m_write=%b m_addr=%x m_dataout=%x m_datain=%x m_readturn=%b m_writeturn=%b\n\tjumpregx=%b bypass=%x eixr=%b ixa=%b cflags=%b syslink=%d",
		$time, clk, reset, enable, pcout, instruction, regmuxout, readdata1, readdata2, aluout, m_read, m_write, m_addr, m_dataout, m_datain, m_readturn, m_writeturn, jumpregx, bypass, eixr, ixa, cflags, syslink);
     //$monitor("%t: coreclk=%b bclk=%b instr_addr = %h (%0d) instr = %b (%0d) mem_read=%b mem_write=%b mem_addr=%h (%0d) mem_din=%h (%0d) mem_dout=%h (%0d)",
     //         $time, clock, fasterclock, instr_addr, instr_addr, instr_data, instr_data, mem_read, mem_write, mem_addr, mem_addr, mem_din, mem_din, mem_dout, mem_dout);

endmodule
