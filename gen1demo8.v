`include "gen1defs.v"
module gen1demo8(input[31:0] address, output reg[7:0]data, output reg exception);

reg [7:0] register [63:0];

initial begin						//initializing memory 
//register[0]= 32'b00000000000000010001000000100000;  //add s2,s0,s1
register[0]=8'b00100000;
register[1]=8'b00010000;
register[2]=8'b00000001;
register[3]=8'b00000000;


//register[7]= 32'b10001101000000000000000000000000; //lw s0,0(s8)
//register[8]= 32'b10101100111000100000000000000000; //sw s7,0(s2)
register[4]=8'b00010000;
register[5]=8'b00000000;
register[6]=8'b00000000;
register[7]=8'b10001101;
register[8]=8'b00001111;
register[9]=8'b00000000;
register[10]=8'b11100010;
register[11]=8'b10101100;

register[12]=8'b00000000; // jump-and-link 0
register[13]=8'b00000000;
register[14]=8'b00000000;
register[15]=8'b00001100;

register[16]=8'h50;
register[17]=8'hc0;
register[18]=8'hff;
register[19]=8'h80;
/* The rest are leftover from some initial tests of a MIPS-style precursor to this system. */
//register[1]= 32'b00010000000000010000000000000011;  //beq s0,s1,ins3
//register[2]= 32'b00000000001000100001100000100010; //sub s3,s1,s2
//register[3]= 32'b00000000001000110010000000100100;//and s4,s1,s3
//register[4]= 32'b00000000100000110010100000100101;//or s5,s4,s3
//register[5]= 32'b00100000001001100000000000000011; //addi s6,s1,3
//register[6]= 32'b00100000001001101111111111111101; //addi s6,s1,-3
//register[7]= 32'b10001101000000000000000000000000; //lw s0,0(s8)
//register[8]= 32'b10101100111000100000000000000000; //sw s7,0(s2)
//register[9]= 32'b00010000000000000000000000000110;  //beq s0,s0,ins15
//register[10]= 32'b00000000001000110010000000100100;//and s4,s1,s3
//register[11]= 32'b00000000100000110010100000100101;//or s5,s4,s3
//register[12]= 32'b00100000001001100000000000000011; //addi s6,s1,3
//register[13]= 32'b00100000001001101111111111111101; //addi s6,s1,-3
//register[14]= 32'b10001101000000000000000000000000; //lw s0,0(s8)
//register[15]= 32'b00001100000000000000000000000000;  //jump-and-link ins0 (r0=next ip)
//register[15]= 32'b11111100000000000000000000000000;  // invalid instruction
//register[15]= 32'b00000000000000000000000000001000;  //jump-to-register r0 (actually to r0=r0+r0 but still = 0)
//register[16]= 32'b00000000000000000000000000001000;  //jump-to-register r0 (actually to r0=r0+r0 but still = 0)
//register[15]= 32'b00001000000000000000000000000000;  //jump ins0
end

wire [31:0]iaddr;
//`ifdef GEN1_WORDADDR
assign iaddr = address;
//`else
//assign iaddr = address >> 2;
//`endif

always @ (iaddr)
begin
if (iaddr < 64) begin
	data=register[iaddr];			//checking which instruction to forward 
	exception = 0;
end else begin
	data = 0;
	exception = 1;
end
end

endmodule

