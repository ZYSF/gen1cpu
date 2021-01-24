module SimpleTests();

	reg clk = 0;
	wire LED0;
	wire LED1;
	wire LED2;
	wire LED3;
	
	SimpleMCU mcu(clk, LED0, LED1, LED2, LED3);
	
	always #10 clk = !clk;
	
	//initial
	//	$monitor("%t: clock=%b LED0=%b LED1=%b LED2=%b LED3=%b", $time, clk, LED0, LED1, LED2, LED3);

endmodule
