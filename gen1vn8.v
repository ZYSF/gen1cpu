`include "gen1defs.v"
module gen1vn8(
	input clk,
	input reset,
	input enable,
	`ifdef GEN1_INT64
	output reg [63:0]xaddr,
	`else
	output reg [31:0]xaddr,
	`endif
	input [7:0]xdin,
	output reg [7:0]xdout,
	output reg memexec,
	output reg memread,
	output reg memwrite,
	input busx,
	output reg busxa,
	input memready,
	output sysmode,
	output reg [5:0] stage,
	output [5:0] innerstage
);
	reg [31:0] tmp;
	reg [5:0] nextstage;
	reg [1:0] part;
	reg [1:0] nextpart;
	`ifdef GEN1_INT64
	wire [31:0] inneraddr;
	`else
	wire [31:0] inneraddr;
	`endif
	reg [31:0] innerdin;
	wire [31:0] innerdout;
	wire innermemexec;
	wire innermemread;
	wire innermemwrite;
	reg innerbusx;
	wire innerbusxa;
	reg innermemready;
	
	gen1vn core(clk, reset, enable, inneraddr, innerdin, innerdout, innermemexec, innermemread, innermemwrite, innerbusx, innerbusxa, innermemready, sysmode, innerstage);
	always @(posedge clk) begin
		if (reset) begin
			stage = 0;
			//nextstage = 0;
		end else if (enable) begin
			stage = nextstage;
		end
	end
	reg [3:0] innerwait;
	reg [3:0] ninnerwait;
	always @(negedge clk) begin
		if (reset) begin
			
		end else begin
			case(stage)
				0: begin
					innermemready = 0;
					innerbusx = 0;
					busxa = 0;
					tmp = 0;
					memexec = 0;
					memread = 0;
					memwrite = 0;
					nextstage = 1;
					part = 0;
					xaddr=0;
					innerwait = 0;
					ninnerwait = 1;
				end
				
				1: begin
					if (innermemread || innermemexec) begin
						if (innerwait == 1) begin
							nextstage = 10;
						end else begin
							nextstage = 1;
							innerwait = ninnerwait;
						end
					end else if (innermemwrite) begin
						if (innerwait == 1) begin
							nextstage = 20;
						end else begin
							nextstage = 1;
							innerwait = ninnerwait;
						end
					end else begin
						nextstage = 1;
					end
				end	
				
				10: begin
					xaddr = inneraddr + part;
					memread = 1;
					memexec = innermemexec;
					nextstage = 11;
					//part = 0;
				end
				
				11: begin
					if (busx) begin
						nextstage = 30;
					end else if (memready) begin
						case(part)
							0: tmp[7:0] = xdin[7:0];
							1: tmp[15:8] = xdin[7:0];
							2: tmp[23:16] = xdin[7:0];
							3: tmp[31:24] = xdin[7:0];
						endcase
						nextstage = 12;
						nextpart = part + 1;
					end else begin
						nextstage = 11;
					end
				end
				
				12: begin
					memread = 0;
					if (nextpart[1:0] == 0) begin
						innermemready = 1;
						innerdin = tmp;
						nextstage = 0;
					end else begin
						part = nextpart;
						nextstage = 10;
					end
				end
				
				20: begin
					xaddr = inneraddr + part;
					memwrite = 1;
					nextstage = 21;
					tmp = innerdout;
				end
				
				21: begin
					case(part)
						0: xdout[7:0] = tmp[7:0];
						1: xdout[7:0] = tmp[15:8];
						2: xdout[7:0] = tmp[23:16];
						3: xdout[7:0] = tmp[31:24];
					endcase
					nextstage = 22;
				end
				
				22: begin
					if (busx) begin
						nextstage = 30;
					end else if (memready) begin
						nextstage = 23;
						nextpart = part + 1;
					end else begin
						nextstage = 21;
					end
				end
				
				23: begin
					memread = 0;
					if (nextpart == 0) begin
						innermemready = 1;
						part = nextpart;
						nextstage = 0;
					end else begin
						nextstage = 20;
					end
				end
				
				30: begin
					memread = 0;
					memwrite = 0;
					innerbusx = 1;
					busxa = 1;
					nextstage = 31;
				end
				
				31: begin
					if (busx) begin
						nextstage = 31;
					end else begin
						nextstage = 32;
					end 
				end
				
				32: begin
					if (innerbusxa) begin
						innerbusx = 0;
						nextstage = 0;
					end else begin
						nextstage = 32;
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
	
	//gen1 core(innerclk, innerreset, enable, pcout,instr,innermread,innermwrite,addr,din,dout,innerreadturn,innerwriteturn,iixr,ixa,ixt,sysflags);
endmodule
