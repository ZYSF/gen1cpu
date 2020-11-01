`include "gen1defs.v"
module gen1vn(
	input clk,
	input reset,
	input enable,
	`ifdef GEN1_INT64
	output reg [63:0]xaddr,
	`else
	output reg [31:0]xaddr,
	`endif
	input [31:0]xdin,
	output [31:0]xdout,
	output reg memexec,
	output reg memread,
	output reg memwrite,
	input busx,
	output reg busxa,
	input memready,
	output sysmode,
	output reg [5:0] stage
);
	reg [31:0] instr;
	
	reg [31:0] din;
	//reg [5:0] stage;
	reg [5:0] nextstage;
	reg insx;
	reg memx;
	reg innerclk;
	reg innerreset;
	reg innerenable;
	reg doinginstr;
	reg doingmem;
	reg memhack;
	wire innermread;
	wire innermwrite;
	always @(posedge clk) begin
		if (reset) begin
			stage = 0;
			
		end else if (enable) begin
			stage = nextstage;
		end
	end
	always @(negedge clk) begin
		if (reset) begin
			//stage = 0;
			//nextstage = 0;
			//innerreset = 1;
			innerclk = 0;
			doinginstr = 0;
			memexec = 0;
			memread = 0;
			memwrite = 0;
			instr = 0;
			nextstage = 0;
			innerreset = 1;
			innerenable = 0;
			innerclk = 1;
			insx = 0;
			memx = 0;
		end else begin
			case(stage)
				0: begin
					innerreset = 0;
					innerclk = 0;	// Set inner clock low to ensure we're in a stable out-of-cycle state
					//innerreadturn = 0;
					//innerwriteturn = 0;
					doinginstr = 0;
					nextstage = 1;
					memhack = 0;
				end
				1: begin
					innerclk = 1; // Set inner clock high to begin cycle
					nextstage = 11; // A hack...
				end
				11: begin
					innerenable = 1; // Avoid enabling directly after reset to allow time for instruction fetch before PC increment
					nextstage = 2;
				end
				2: begin
						doinginstr = 1; // Clock is now high, inner core should be trying to fetch instruction
						memexec = 1;
						memread = 1;
						memwrite = 0;
						xaddr = pcout;
						innerreadturn = 0;
						innerwriteturn = 0;
					if (memready) begin
						nextstage = 3;
					end else begin
						nextstage = 2;
					end
				end
				3: begin
					nextstage = memready ? 4 : 3;
				end
				4: begin
					if (busx) begin
						instr = 0;
						insx = 1;
						nextstage = 20;
					end else begin
						instr = xdin;
						insx = 0;
						nextstage = 5;
					end
				end
				5: begin
					doinginstr = 0;
					memexec = 0;
					memread = 0;
					memwrite = 0;
					nextstage = innermread || innermwrite ? 6 : 10;
				end
				6: begin
					memexec = 0;
					memread = innermread;
					memwrite = innermwrite;
					xaddr = addr;
					nextstage = 7;
					//innerclk = innermread || innermwrite ? 0 : 1;
					memhack = innermread || innermwrite;
				end
				7: begin
					nextstage = memready ? 8 : 7;
				end
				8: begin
					din = xdin;
					memx = busx;
					memexec = 0;
					memread = 0;
					memwrite = 0;
					innerreadturn = innermread;
					innerwriteturn = innermwrite;
					nextstage = 9;
				end
				9: begin
					innerclk = 0;
					//if (memhack) innerclk = 1;
					nextstage = 10;
				end
				10: begin
					//innerclk = 0;
					//innerreadturn = 0;
					//innerwriteturn = 0;
					if (insx && insxa) begin
						insx = 0;
					end
					if (memx && memxa) begin
						memx = 0;
					end
					nextstage = 0;
				end
				
				20: begin
					innerclk = 0;
					memread = 0;
					memwrite = 0;
					memexec = 0;
					nextstage = 21;
				end
				
				21: begin
					if (insxa) begin
						//insx = 0;
						busxa = 1;
						nextstage = 22;
					end else begin
						busxa = 3;
						nextstage = 40;
					end
				end
				
				22: begin
					if (busx) begin
						nextstage = 22;
					end else begin
						busxa = 0;
						nextstage = 1;
					end
				end
				
				30: begin
					innerclk = 0;
					memread = 0;
					memwrite = 0;
					memexec = 0;
					nextstage = 31;
				end
				
				31: begin
					if (memxa) begin
						//memx = 0;
						busxa = 1;
						nextstage = 32;
					end else begin
						busxa = 3;
						nextstage = 40;
					end
				end
				
				32: begin
					if (busx) begin
						nextstage = 32;
					end else begin
						busxa = 0;
						nextstage = 1;
					end
				end
				
				40: begin
					//addr = 0xFFFFFFFF;
					nextstage = 41;
				end
				
				41: begin
					//addr = 0x00000000;
					nextstage = 40;
				end
				
				default: begin
					nextstage = 40;
				end
			endcase
		end
	end
	wire [31:0] pcout;
	//assign xpcout[7:0] = pcout[9:2];
	wire [31:0] addr;
	//assign xaddr[7:0] = addr[9:2];
	wire [31:0] dout;
	assign xdout[31:0] = dout[31:0];
	//wire [31:0] din;
	//assign din[31:0] = xdin[31:0];
	//assign din[31:8] = 0;
	wire [15:0]iixr;
	assign iixr[1:0] = 0;
	assign iixr[2:2] = insx;
	assign iixr[3:3] = memx;
	assign iixr[15:4] = 0;
	wire [15:0]ixa;
	assign insxa = ixa[2:2];
	assign memxa = ixa[3:3];
	wire [3:0]ixt;
	wire [3:0]sysflags;
	assign sysmode = sysflags[0:0];
	reg innerreadturn;
	reg innerwriteturn;
	gen1 core(innerclk, innerreset, innerenable, pcout,instr,innermread,innermwrite,addr,din,dout,innerreadturn,innerwriteturn,iixr,ixa,ixt,sysflags);
endmodule
